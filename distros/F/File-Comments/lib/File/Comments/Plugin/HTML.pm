###########################################
# File::Comments::Plugin::HTML 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::HTML;
###########################################

use strict;
use warnings;
use File::Comments::Plugin;
use Log::Log4perl qw(:easy);
use HTML::TokeParser;

our $VERSION = "0.01";
our @ISA     = qw(File::Comments::Plugin);

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->register_suffix(".htm");
    $self->register_suffix(".html");
    $self->register_suffix(".HTML");
    $self->register_suffix(".HTM");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "html";
}

###########################################
sub comments {
###########################################
    my($self, $target) = @_;

    return $self->extract_html_comments($target);
}

###########################################
sub stripped {
###########################################
    my($self, $target) = @_;

    return $self->strip_html_comments($target);
}

###########################################
sub extract_html_comments {
###########################################
    my($self, $target) = @_;

    my @comments = ();

    my $stream = HTML::TokeParser->new(
                 \$target->{content});

    while(my $token = $stream->get_token()) {
        next unless $token->[0] eq "C";

        $token->[1] =~ s/^<!--//;
        $token->[1] =~ s/-->$//;

        push @comments, $token->[1];
    }

    return \@comments;
}

###########################################
sub strip_html_comments {
###########################################
    my($self, $target) = @_;

    require HTML::TreeBuilder;

    my $root = HTML::TreeBuilder->new();
    $root->parse($target->{content});
    if(!$root) {
        WARN "Cannot parse $target->{path}";
        return $target->{content};
    }
    my $stripped_html = $root->as_HTML();
    # HTML::Element < 4 appends a newline to the HTML
    # for no apparent reason (CPAN RT#41739)
    $stripped_html =~ s/\n$//;
    return $stripped_html;
}

1;

__END__

=head1 NAME

File::Comments::Plugin::HTML - Plugin to detect comments in HTML source code

=head1 SYNOPSIS

    use File::Comments::Plugin::HTML;

=head1 DESCRIPTION

File::Comments::Plugin::HTML is a plugin for the File::Comments framework.

It uses HTML::TokeParser to extracts comments from HTML files.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
