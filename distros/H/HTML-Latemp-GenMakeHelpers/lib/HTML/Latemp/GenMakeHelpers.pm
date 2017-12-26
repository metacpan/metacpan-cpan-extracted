package HTML::Latemp::GenMakeHelpers;
$HTML::Latemp::GenMakeHelpers::VERSION = 'v0.5.2';
use strict;
use warnings;

use 5.008;

package HTML::Latemp::GenMakeHelpers::Base;
$HTML::Latemp::GenMakeHelpers::Base::VERSION = 'v0.5.2';
sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

package HTML::Latemp::GenMakeHelpers::HostEntry;
$HTML::Latemp::GenMakeHelpers::HostEntry::VERSION = 'v0.5.2';
our @ISA=(qw(HTML::Latemp::GenMakeHelpers::Base));

use Class::XSAccessor accessors => {'dest_dir' => 'dest_dir', 'id' => 'id', 'source_dir' => 'source_dir',};

sub initialize
{
    my $self = shift;
    my %args = (@_);

    $self->id($args{'id'});
    $self->source_dir($args{'source_dir'});
    $self->dest_dir($args{'dest_dir'});
}

package HTML::Latemp::GenMakeHelpers::Error;
$HTML::Latemp::GenMakeHelpers::Error::VERSION = 'v0.5.2';
our @ISA=(qw(HTML::Latemp::GenMakeHelpers::Base));

package HTML::Latemp::GenMakeHelpers::Error::UncategorizedFile;
$HTML::Latemp::GenMakeHelpers::Error::UncategorizedFile::VERSION = 'v0.5.2';
our @ISA=(qw(HTML::Latemp::GenMakeHelpers::Error));

use Class::XSAccessor accessors => {'file' => 'file', 'host' => 'host',};

sub initialize
{
    my $self = shift;
    my $args = shift;

    $self->file($args->{'file'});
    $self->host($args->{'host'});

    return 0;
}

package HTML::Latemp::GenMakeHelpers;


our @ISA=(qw(HTML::Latemp::GenMakeHelpers::Base));

use File::Find::Rule;
use File::Basename;

use Class::XSAccessor accessors => {'_common_buckets' => '_common_buckets', '_base_dir' => 'base_dir', '_filename_lists_post_filter' => '_filename_lists_post_filter', 'hosts' => 'hosts', '_hosts_id_map' => 'hosts_id_map',};


sub initialize
{
    my $self = shift;
    my (%args) = (@_);

    $self->_base_dir("src");
    $self->_filename_lists_post_filter(
        $args{filename_lists_post_filter} || sub {
            my ($params) = @_;
            return $params->{filenames};
        }
    );
    $self->hosts(
        [
        map {
            HTML::Latemp::GenMakeHelpers::HostEntry->new(
                %$_
            ),
        }
        @{$args{'hosts'}}
        ]
        );
    $self->_hosts_id_map(+{ map { $_->{'id'} => $_ } @{$self->hosts()}});
    $self->_common_buckets({});

    return;
}

sub process_all
{
    my $self = shift;
    my $dir = $self->_base_dir();

    my @hosts = @{$self->hosts()};

    open my $file_lists_fh, ">", "include.mak";
    open my $rules_fh, ">", "rules.mak";

    print {$rules_fh} "COMMON_SRC_DIR = " . $self->_hosts_id_map()->{'common'}->{'source_dir'} . "\n\n";

    foreach my $host (@hosts)
    {
        my $host_outputs = $self->process_host($host);
        print {$file_lists_fh} $host_outputs->{'file_lists'};
        print {$rules_fh} $host_outputs->{'rules'};
    }

    print {$rules_fh} "latemp_targets: " . join(" ", map { '$('.uc($_->{'id'})."_TARGETS)" } grep { $_->{'id'} ne "common" } @hosts) . "\n\n";

    close($rules_fh);
    close($file_lists_fh);
}

sub _make_path
{
    my $self = shift;

    my $host = shift;
    my $path = shift;

    return $host->source_dir() . "/" . $path;
}


sub get_initial_buckets
{
    my $self = shift;
    my $host = shift;

    return
    [
        {
            'name' => "IMAGES",
            'filter' =>
            sub
            {
                my $fn = shift;
                return ($fn !~ /\.(?:tt|w)ml\z/) && (-f $self->_make_path($host, $fn))
            },
        },
        {
            'name' => "DIRS",
            'filter' =>
            sub
            {
                return (-d $self->_make_path($host, shift))
            },
            filter_out_common => 1,
        },
        {
            'name' => "DOCS",
            'filter' =>
            sub
            {
                return shift =~ /\.x?html\.wml\z/;
            },
            'map' => sub {
                my $fn = shift;
                $fn =~ s{\.wml\z}{};
                return $fn;
            },
        },
        {
            'name' => "TTMLS",
            'filter' =>
            sub
            {
                return shift =~ /\.ttml\z/;
            },
            'map' => sub {
                my $fn = shift;
                $fn =~ s{\.ttml\z}{};
                return $fn;
            },
        },
    ];
}

sub _identity
{
    return shift;
}

sub _process_bucket
{
    my ($self, $bucket) = @_;
    return
        {
            %$bucket,
            'results' => [],
            (
                (!exists($bucket->{'map'})) ?
                    ('map' => \&_identity) :
                    ()
            ),
        };
}


sub get_buckets
{
    my ($self, $host) = @_;

    return
        [
            map
            { $self->_process_bucket($_) }
            @{$self->get_initial_buckets($host)}
        ];
}

sub _filter_out_special_files
{
    my ($self, $host, $files_ref) = @_;

    my @files = @$files_ref;

    @files = (grep { ! m{(\A|/)\.svn(/|\z)} } @files);
    @files = (grep { ! /~\z/ } @files);
    @files =
        (grep
        {
            my $bn = basename($_);
            not (($bn =~ /\A\./) && ($bn =~ /\.swp\z/))
        }
        @files
        );

    return \@files;
}

sub _sort_files
{
    my ($self, $host, $files_ref) = @_;

    return [ sort { $a cmp $b } @$files_ref ];
}


sub get_non_bucketed_files
{
    my ($self, $host) = @_;

    my $source_dir_path = $host->source_dir();

    my $files = [ File::Find::Rule->in($source_dir_path) ];

    s!^$source_dir_path/!! for @$files;
    $files = [grep { $_ ne $source_dir_path } @$files];

    $files = $self->_filter_out_special_files($host, $files);

    return $self->_sort_files($host, $files);
}


sub place_files_into_buckets
{
    my ($self, $host, $files, $buckets) = @_;

    FILE_LOOP:
    foreach my $f (@$files)
    {
        foreach my $bucket (@$buckets)
        {
            if ($bucket->{'filter'}->($f))
            {
                if ($host->{'id'} eq "common")
                {
                    $self->_common_buckets->{$bucket->{name}}->{$f} = 1;
                }

                if (   ($host->{'id'} eq "common")
                    ||
                    (!(
                        $bucket->{'filter_out_common'}
                            &&
                        exists($self->_common_buckets->{$bucket->{name}}->{$f})
                    ))
                )
                {
                    push @{$bucket->{'results'}}, $bucket->{'map'}->($f);
                }

                next FILE_LOOP;
            }
        }
        die HTML::Latemp::GenMakeHelpers::Error::UncategorizedFile->new(
            {
                'file' => $f,
                'host' => $host->id(),
            }
        );
    }
}


sub get_rules_template
{
    my ($self, $host) = @_;

    my $h_dest_star = "\$(X8X_DEST)/%";
    my $wml_path = qq{WML_LATEMP_PATH="\$\$(perl -MFile::Spec -e 'print File::Spec->rel2abs(shift)' '\$\@')"};
    my $dest_dir = $host->dest_dir();
    my $source_dir_path = $host->source_dir();

    return <<"EOF";

X8X_SRC_DIR = $source_dir_path

X8X_DEST = $dest_dir

X8X_TARGETS = \$(X8X_DEST) \$(X8X_DIRS_DEST) \$(X8X_COMMON_DIRS_DEST) \$(X8X_COMMON_IMAGES_DEST) \$(X8X_COMMON_DOCS_DEST) \$(X8X_COMMON_TTMLS_DEST) \$(X8X_IMAGES_DEST) \$(X8X_DOCS_DEST) \$(X8X_TTMLS_DEST)

X8X_WML_FLAGS = \$(WML_FLAGS) -DLATEMP_SERVER=x8x

X8X_TTML_FLAGS = \$(TTML_FLAGS) -DLATEMP_SERVER=x8x

X8X_DOCS_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(X8X_DOCS))

X8X_DIRS_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(X8X_DIRS))

X8X_IMAGES_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(X8X_IMAGES))

X8X_TTMLS_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(X8X_TTMLS))

X8X_COMMON_IMAGES_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(COMMON_IMAGES))

X8X_COMMON_DIRS_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(COMMON_DIRS))

X8X_COMMON_TTMLS_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(COMMON_TTMLS))

X8X_COMMON_DOCS_DEST = \$(patsubst %,\$(X8X_DEST)/%,\$(COMMON_DOCS))

\$(X8X_DOCS_DEST) : $h_dest_star : \$(X8X_SRC_DIR)/%.wml \$(DOCS_COMMON_DEPS)
	 $wml_path ; ( cd \$(X8X_SRC_DIR) && wml -o "\$\${WML_LATEMP_PATH}" \$(X8X_WML_FLAGS) -DLATEMP_FILENAME=\$(patsubst $h_dest_star,%,\$(patsubst %.wml,%,\$@)) \$(patsubst \$(X8X_SRC_DIR)/%,%,\$<) )

\$(X8X_TTMLS_DEST) : $h_dest_star : \$(X8X_SRC_DIR)/%.ttml \$(TTMLS_COMMON_DEPS)
	ttml -o \$@ \$(X8X_TTML_FLAGS) -DLATEMP_FILENAME=\$(patsubst $h_dest_star,%,\$(patsubst %.ttml,%,\$@)) \$<

\$(X8X_DIRS_DEST) : $h_dest_star : unchanged
	mkdir -p \$@
	touch \$@

\$(X8X_IMAGES_DEST) : $h_dest_star : \$(X8X_SRC_DIR)/%
	cp -f \$< \$@

\$(X8X_COMMON_IMAGES_DEST) : $h_dest_star : \$(COMMON_SRC_DIR)/%
	cp -f \$< \$@

\$(X8X_COMMON_TTMLS_DEST) : $h_dest_star : \$(COMMON_SRC_DIR)/%.ttml \$(TTMLS_COMMON_DEPS)
	ttml -o \$@ \$(X8X_TTML_FLAGS) -DLATEMP_FILENAME=\$(patsubst $h_dest_star,%,\$(patsubst %.ttml,%,\$@)) \$<

\$(X8X_COMMON_DOCS_DEST) : $h_dest_star : \$(COMMON_SRC_DIR)/%.wml \$(DOCS_COMMON_DEPS)
	$wml_path ; ( cd \$(COMMON_SRC_DIR) && wml -o "\$\${WML_LATEMP_PATH}" \$(X8X_WML_FLAGS) -DLATEMP_FILENAME=\$(patsubst $h_dest_star,%,\$(patsubst %.wml,%,\$@)) \$(patsubst \$(COMMON_SRC_DIR)/%,%,\$<) )

\$(X8X_COMMON_DIRS_DEST)  : $h_dest_star : unchanged
	mkdir -p \$@
	touch \$@

\$(X8X_DEST): unchanged
	mkdir -p \$@
	touch \$@
EOF
}


sub process_host
{
    my $self = shift;
    my $host = shift;

    my $dir = $self->_base_dir();

    my $source_dir_path = $host->source_dir();

    my $file_lists_text = "";
    my $rules_text = "";

    my $files = $self->get_non_bucketed_files($host);

    my $buckets = $self->get_buckets($host);

    $self->place_files_into_buckets($host, $files, $buckets);

    my $id = $host->id();
    my $host_uc = uc($id);
    foreach my $bucket (@$buckets)
    {
        my $name = $bucket->{name};
        $file_lists_text .= $host_uc . "_" . $name . " =" . join("", map { " $_" } @{$self->_filename_lists_post_filter->({filenames => $bucket->{'results'}, bucket => $name, host => $id,})}) . "\n";
    }

    if ($id ne "common")
    {
        my $rules = $self->get_rules_template($host);

        $rules =~ s!X8X!$host_uc!g;
        $rules =~ s!x8x!$id!ge;
        $rules_text .= $rules;
    }

    return
        {
            'file_lists' => $file_lists_text,
            'rules' => $rules_text,
        };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Latemp::GenMakeHelpers - A Latemp Utility Module.

=head1 VERSION

version v0.5.2

=head1 SYNOPSIS

    use HTML::Latemp::GenMakeHelpers;

    my $generator =
        HTML::Latemp::GenMakeHelpers->new(
            'hosts' =>
            [ map {
                +{ 'id' => $_, 'source_dir' => $_,
                    'dest_dir' => "\$(ALL_DEST_BASE)/$_-homepage"
                }
            } (qw(common t2 vipe)) ],
        );

    $generator->process_all();

=head1 API METHODS

=head2 my $generator = HTML::Latemp::GenMakeHelpers->new(hosts => [@hosts])

Construct an object with the host defined in @hosts.

An optional parameter is C<'filename_lists_post_filter'> which must point
to a subroutine that accepts a hash reference of C<'host'>, C<'bucket'>,
and C<'filenames'> (which points to an array reference) and returns the
modified list of filenames as an array reference (it is called separately
for each host and bucket).

An example for it is:

    filename_lists_post_filter => sub {
        my ($args) = @_;
        my $filenames = $args->{filenames};
        if ($args->{host} eq 'src' and $args->{bucket} eq 'IMAGES')
        {
            return [ grep { $_ !~ m#arrow-right# } @$filenames ];
        }
        else
        {
            return $filenames;
        }
    },

(This parameter was added in version 0.5.0 of this module.)

=head2 $generator->process_all()

Process all hosts.

=head1 INTERNAL METHODS

=head2 initialize()

Called by the constructor to initialize the object. Can be sub-classes by
derived classes.

=head2 $generator->hosts()

Returns an array reference of HTML::Latemp::GenMakeHelpers::HostEntry for
the hosts.

=head2 $generator->get_initial_buckets($host)

Get the initial buckets for the host $host.

=head2 $generator->get_buckets($host)

Get the processed buckets.

=head2 $self->get_non_bucketed_files($host)

Get the files that were not placed in any bucket.

=head2 $self->place_files_into_buckets($host, $files, $buckets)

Sort the files into the buckets.

=head2 $self->get_rules_template($host)

Get the makefile rules template for the host $host.

=head2 $self->process_host($host)

Process the host $host.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-latemp-genmakehelpers@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Latemp-GenMakeHelpers>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the MIT X11 License.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Latemp-GenMakeHelpers> or
by email to
L<bug-html-latemp-genmakehelpers@rt.cpan.org|mailto:bug-html-latemp-genmakehelpers@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc HTML::Latemp::GenMakeHelpers

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Latemp-GenMakeHelpers>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-Latemp-GenMakeHelpers>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Latemp-GenMakeHelpers>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-Latemp-GenMakeHelpers>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-Latemp-GenMakeHelpers>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Latemp-GenMakeHelpers>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Latemp-GenMakeHelpers>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Latemp-GenMakeHelpers>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Latemp::GenMakeHelpers>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-latemp-genmakehelpers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Latemp-GenMakeHelpers>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thewml/latemp>

  git clone https://github.com/thewml/latemp

=cut
