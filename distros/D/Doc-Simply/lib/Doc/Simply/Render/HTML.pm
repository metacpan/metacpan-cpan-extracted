package Doc::Simply::Render::HTML;

use Any::Moose;
use Doc::Simply::Carp;

use Doc::Simply::Render::HTML::TT;

use Text::MultiMarkdown qw/markdown/;
use Template;
use HTML::Declare qw/LINK SCRIPT STYLE/;

use constant YUI_reset_fonts_grids_base => "http://yui.yahooapis.com/combo?2.8.1/build/reset-fonts-grids/reset-fonts-grids.css&2.8.1/build/base/base-min.css";
use constant YUI_reset => "http://yui.yahooapis.com/combo?2.8.1/build/reset/reset-min.css";


has tt => qw/is ro lazy_build 1 isa Template/;
sub _build_tt {
    my $self = shift;
    my $method = "build_tt";
    croak "Don't have method \"$method\"" unless my $build = $self->can($method);
    my $got = $build->($self, @_);

    return $got if blessed $got && $got->isa("Template");
    return Template->new($got) if ref $got eq "HASH";
    return Template->new unless $got;

    croak "Don't know how to build Template with $got";
}

sub build_tt {
    return {
        Doc::Simply::Render::HTML::TT->build,
    };
}

sub process_tt {
    my $self = shift;
    my %given = @_;

    my ($input, $output, $context, @process);

    {
        $input = $given{input};
        croak "Wasn't given input" unless defined $input;
    }

    {
        $output = $given{output};
        my $output_content;
        $output = \$output_content unless exists $given{output};

        if (blessed $output) {
            if ($output->isa("Path::Resource")) {
                $output = $output->file;
            }
            if ($output->isa("Path::Class::File")) {
                $output = "$output";
            }
        }

        if (defined $output && ! ref $output) {
            $output = Path::Class::File->new($output);
            $output->parent->mkpath unless -d $output->parent;
            $output = "$output";
        }
    }

    {
        $context = $given{context} || {};
    }

    if ($given{process}) {
        @process = @{ $given{process} };
    }
    else {
        @process = qw/binmode :utf8/;
    }

    my $tt = $self->tt;
    $tt->process($input, $context, $output, @process) or croak "Couldn't process $input => $output: ", $tt->error;

    return $$output unless exists $given{output};

    return $output if ref $output eq "SCALAR";
}

sub css_render {
    my $self = shift;
    my $given = shift;

    croak "Don't understand $given" unless ref $given eq "HASH";

    my $value;
    if ($value = $given->{link}) {
        return LINK { rel => 'stylesheet', type => 'text/css', href => $value };
    }
    elsif ($value = $given->{content}) {
        $value = $$value if ref $value eq "SCALAR";
        return STYLE { type => 'text/css', _ => $value };
    }
    else {
        croak "Don't understand \"@{[ %$given ]}\"";
    }
}

sub js_render {
    my $self = shift;
    my $given = shift;

    croak "Don't understand $given" unless ref $given eq "HASH";

    my $value;
    if ($value = $given->{link}) {
        return SCRIPT { type => 'text/jascript', src => $value, content => [] };
    }
    else {
        croak "Don't understand \"@{[ %$given ]}\"";
    }
}

sub render {
    my $self = shift;
    my %given = @_;

    my $document = $given{document} or croak "Wasn't given document to format";
    my $root = $document->root;

    my ($content, @css, @js);

    my @index;

    {
        my %state;
        $content = "";
        $root->walk_down({ callback => sub {
            my $node = shift;
            my $_content = $node->content;
            if ($node->tag =~ m/^head\d+$/) {
                push @index, $node;
                if ($_content =~ m/^\s*NAME\s*$/ && ! $state{got_name}) {
                    # TODO Move this into the parser
                    $state{saw_name} = 1;
                }
                $_content = join '', "<a name=\"$_content\"></a>", $_content;
            }
            else {
                if ($state{saw_name} && $_content =~ m/\S/) {
                    delete $state{saw_name};
                    my ($title, $name, $subtitle) = ($_content);
                    chomp $title;
                    $title =~ m/^\s*([^-]+)?(?:\s*-\s+(.*))?$/;
                    $name = $1;
                    $subtitle = $2;
                    @{ $document->appendix }{qw/name title subtitle/} = ($name, $title, $subtitle);
                    $state{got_name} = 1;

                }
            }
            $content .= $self->_format_tag($node->tag, $_content);
            return 1;
        } });
        $content = markdown $content, { heading_ids => 0 };
    }

    my $style = lc ($given{style} || "standard");

    if ($style eq "standard") {
        push @css, $self->css_render({ link => YUI_reset_fonts_grids_base });
        push @css, $self->css_render({ content => Doc::Simply::Render::HTML::TT->css_standard });
    }
    elsif ($style eq "base") {
        push @css, $self->css_render({ link => YUI_reset_fonts_grids_base });
    }
    elsif ($style eq "reset") {
        push @css, $self->css_render({ link => YUI_reset });
    }
    else {
        croak "Don't understand style \"$style\"";
    }

    {
        my $css = $given{css} || [];
        for (@$css) {
            push @css, $self->css_render($_);
        }
    }

    {
        my $css = $given{js} || [];
        for (@$css) {
            push @css, $self->js_render($_);
        }
    }

    $self->process_tt( input => "document", context => { index => \@index, document => $document, content => $content, css => \@css, js => \@js } );
}

sub _format_tag {
    my $self = shift;
    my $tag = shift;
    my $content = shift;

    if ($tag =~ m/^head(\d)/) {
        return "<h$1 class=\"content-head$1 content-head\">$content</h$1>\n";
    }

    return $content;
}

#my $content = $document->content_from;
#warn markdown $content;

1;
