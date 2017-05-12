package Lang::Tree::Builder;

use strict;
use warnings;

use Lang::Tree::Builder::Parser;
use Template;
use FileHandle;

our $VERSION = '0.1';

=head1 NAME

Lang::Tree::Builder - Build Classes from a Tree Definition File

=head1 SYNOPSIS

  use Lang::Tree::Builder;
  my $builder = new Lang::Tree::Builder(%params);
  $builder->build($config_file);

=head1 DESCRIPTION

C<Lang::Tree::Builder> takes a set of parameters and a tree definition file
and uses L<Template::Toolkit> to generate perl classes and an API.

It is intended primarily to take the drudgery out of writing all of
the support classes needed to build abstract syntax trees.

=head2 new

  my $builder = new Lang::Tree::Builder(%params);

C<%params> are

=over 4

=item dir

The output directory, default C<./>

=item prefix

A prefix class prepended to all generated classes, default none.
If a prefix is provided, it is used literally. i.e. if you want
C<MyPrefix::> you must supply the C<::> explicitly.

=item lang

The language of the generated classes.

=back

=cut

sub new {
    my ($class, %params) = @_;

    my %defaults = (
        dir    => '.',
        prefix => '',
        lang   => 'Perl',
    );

    foreach my $key (keys %params) {
        die "unrecognised param: $key" unless exists $defaults{$key};
    }

    my %body;

    foreach my $key (keys %defaults) {
        $body{$key} =
          exists($params{$key})
          ? $params{$key}
          : $defaults{$key};
    }

    my $self = bless {%body}, $class;
    $self->{includes} = $self->findIncludes();
    $self->{ext}      = $self->getExt();
    $self->initVmethods();

    # add to this hash for new kinds of targets
    $self->{TEMPLATES} = {
        visitor => 'Visitor',
        cvis    => 'CopyingVisitor',
        printer => 'Printer',
        xml     => 'XML',
        api     => 'API',
    };

    return $self;
}

{
    my $init = 0;

    sub initVmethods {
        unless ($init) {
            $Template::Stash::SCALAR_OPS->{camelcase} = sub {
                my ($text) = @_;
                $text =~ s/_(\w)/uc($1)/eg;
                ucfirst($text);
            };

            $Template::Stash::SCALAR_OPS->{uncamel} = sub {
                my ($text) = @_;
                $text =~ s/([A-Z])/'_' . lc($1)/eg;
                $text =~ s/^_//;
                $text;
            };

            $Template::Stash::SCALAR_OPS->{tolower} = sub {
                my ($text) = @_;
                lc($text);
            };

            $Template::Stash::SCALAR_OPS->{getMethod} = sub {
                my ($text) = @_;
                $text =~ s/_(\w)/uc($1)/eg;
                'get' . ucfirst($text);
            };

            $Template::Stash::LIST_OPS->{sz} = sub {
                my ($list) = @_;
                scalar(@$list);
            };

            $init = 1;
        }
    }
}

=head2 build

  $builder->build($config_file);

Builds the tree classes, API and Visitor from definitions
in the C<$config_file>.

=cut

sub build {
    my ($self, $config_file) = @_;

    my $data = $self->getData($config_file);
    $self->buildClasses($data, $config_file);
    $self->buildSpecialClasses($data, $config_file);
}

# parses the $config file and returns its $data
sub getData {
    my ($self, $config_file) = @_;

    my $parser = Lang::Tree::Builder::Parser->new(prefix => $self->{prefix});
    return $parser->parseFile($config_file);
}

# build each class file from the $data
sub buildClasses {
    my ($self, $data, $config_file) = @_;

    foreach my $class ($data->classes) {
        $self->buildClass($data, $config_file, $class);
    }
}

# build an individual class file
sub buildClass {
    my ($self, $data, $config_file, $class) = @_;

    $self->runTemplate($data, $config_file, 'Class.tt2', $class,
        class => $class);
}

sub buildSpecialClasses {
    my ($self, $data, $config_file) = @_;
    foreach my $key (keys %{$self->{TEMPLATES}}) {
        $self->buildSpecialClass($data, $config_file, $self->{TEMPLATES}{$key});
    }
}

sub buildSpecialClass {
    my ($self, $data, $config_file, $template) = @_;
    $self->runTemplate($data, $config_file, "$template.tt2",
        $self->makeSpecialClass($template));
}

sub runTemplate {
    my ($self, $data, $config_file, $input_template, $output_class, %extra)
      = @_;

    unless ($self->findTemplate($input_template)) {
        warn "templates $input_template not found\n";
        return;
    }
    my $template = $self->makeTemplate();
    $template->process(
        $input_template,
        $self->makeVars($data, $config_file, %extra),
        $self->getOutputFilename($output_class)
    ) or die "builder failed: ", $template->error();
}

# create the vars hash for the template
sub makeVars {
    my ($self, $data, $config_file, %extra) = @_;

    return {
        warning => $self->makeWarning($config_file),
        data    => $data,
        %{$self->makeSpecialClasses()},
        ext     => $self->{ext},
        %extra
    };
}

sub makeSpecialClasses {
    my ($self) = @_;
    my $classes = {};
    foreach my $key (keys %{$self->{TEMPLATES}}) {
        $classes->{$key} = $self->makeSpecialClass($self->{TEMPLATES}->{$key});
    }
    return $classes;
}

sub makeSpecialClass {
    my ($self, $class) = @_;
    new Lang::Tree::Builder::Class(class => ($self->{prefix} . $class));
}

# create a new Template object
sub makeTemplate {
    my ($self) = @_;

    Template->new($self->makeTemplateConfig())
      || die "$Template::ERROR\n";
}

# returns the warning message
sub makeWarning {
    my ($self, $config_file) = @_;

    "Automatically generated from $config_file on "
    . scalar(gmtime)
    . " GMT.";
}

# returns a hashref of config for the Template
sub makeTemplateConfig {
    my ($self) = @_;

    return {
        INCLUDE_PATH => $self->{includes},
        INTERPOLATE  => 0,
        POST_CHOMP   => 0,
        EVAL_PERL    => 0,
    };
}

sub findTemplate {
    my ($self, $template) = @_;
    foreach my $inc (@{ $self->{includes} }) {
        return "$inc/$template" if -f "$inc/$template";
    }
    return '';
}

# returns the filename extension for all generated files
sub getExt {
    my ($self) = @_;

    foreach my $inc (@{ $self->{includes} }) {
        my $extfile = "$inc/EXT";
        if (-e $extfile) {
            my $fh = new FileHandle($extfile);
            die "$extfile: $@" unless $fh;
            my $ext = '';
            while (defined(my $line = $fh->getline())) {
                chomp($line);
                $line =~ s/#.*//;
                $line =~ s/\s+//g;
                $ext .= $line;
            }
            return $ext;
        }
    }

    die "can't find EXT";
}

# returns the output filename for an argument Lang::Tree::Builder::Class
sub getOutputFilename {
    my ($self, $class) = @_;

    return $self->{dir} . '/' . $class->name('/') . $self->{ext};
}

# returns an arrayref of locations to search for Templates
sub findIncludes {
    my ($self) = @_;

    [ map { "$_/Tree/Builder/Templates/$self->{lang}" } @INC ];
}

=head1 AUTHOR

  Bill Hails <me@billhails.net>

=head1 SEE ALSO

Full documentation is in the command line interface L<treebuild>.

=cut

1;
