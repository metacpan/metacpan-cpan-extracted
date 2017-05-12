package HTML::Template::Compiled::Plugin::HTML2;

# ABSTRACT: Do not escape all HTML entities

use strict;
use warnings;

use HTML::Template::Compiled;
HTML::Template::Compiled->register(__PACKAGE__);

use HTML::Entities;

our $VERSION = '0.01';

sub register{
    my ($class) = @_;
    my %plugs   = (
        escape => { 
            HTML_WITHOUT_NBSP => \&escape_html,
        },
    );

   return \%plugs;
}

sub escape_html {
    my ($str) = @_;

    return $str unless defined $str;

    $str = HTML::Entities::encode_entities( $str );
    $str =~ s!&amp;nbsp;!&nbsp;!g;
    $str =~ s!&lt;br /&gt;!<br />!g;

    #$str =~ s/&/&amp;/g;
    #$str =~ s/"/&quot;/g;
    #$str =~ s/'/&#39;/g;
    #$str =~ s/>/&gt;/g;
    #$str =~ s/</&lt;/g;

    return $str;
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::HTML2 - Do not escape all HTML entities

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = 'hello>';

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, 'hello&gt;', '> => &gt;';

    my $template = '<%= test ESCAPE=HTML_WITHOUT_NBSP %>';
    my $text     = '&nbsp; hello<br />';

    my $tmpl = HTML::Template::Compiled->new(
        scalarref => \$template,
        plugin    => [ 'HTML::Template::Compiled::Plugin::HTML2' ],
    );

    $tmpl->param( test => $text );
    my $output = $tmpl->output;

    is $output, '&nbsp; hello<br />', 'test';

=head1 DESCRIPTION

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
