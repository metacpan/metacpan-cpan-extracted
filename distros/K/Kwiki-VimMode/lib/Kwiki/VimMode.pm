package Kwiki::VimMode;
use strict;
use warnings;

use Kwiki::Plugin -Base;
use Kwiki::Installer -base;

our $VERSION = 0.05;

const class_title => 'color hiliting using Vim';
const class_id    => 'vim_mode';
const css_file    => 'vim_mode.css';

sub register {
    my $registry = shift;
    $registry->add( wafl => vim => 'Kwiki::VimMode::Wafl' );
}

package Kwiki::VimMode::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    require Text::VimColor;
    my $string = $self->block_text;
    chomp $string;
    $ENV{PATH} = "/usr/local/bin:$ENV{PATH}";
    $string =~ s/^ filetype: \s* (\w+) \s* \n+//sx;
    my @filetype = $1 ? ( filetype => $1 ) : ();
    my $vim = Text::VimColor->new(
        string => $string,
        @filetype,
        vim_options => [ qw( -RXZ -i NONE -u NONE -N ), "+set nomodeline" ]
    );
    return '<pre class="vim">' . $vim->html . "</pre>\n";
}

package Kwiki::VimMode;

__DATA__

=head1 NAME 

Kwiki::VimMode - VimMode preformatted forms of text

=head1 SYNOPSIS

 $ cpan Kwiki::VimMode
 $ cd /path/to/kwiki
 $ echo "Kwiki::VimMode" >> plugins
 $ kwiki -update

=head1 DESCRIPTION

This module allows you to hilight the syntax of any text mode that the Vim editor recognizes:

    Here's some *HTML* and *Perl* for you to grok:
    
    .vim
    <html>
        <head>
            <title>Highlighted stuff!</title>
        </head>
        <body>
            <em>Check</em> <strong>this</strong>
            <code>out!</code>
        </body>
    </html>
    .vim
    
    .vim
    #!/usr/bin/perl
    # sample perl
    $name = 'Kwiki';
    print "Check out $name!\n";
    .vim

L<Text::VimColor>/Vim should hopefully pick up the correct syntax automatically. If it doesn't, precede your text in the C<.vim> block with C<filetype: name>, where C<name> is a valid Vim syntax name. For example:

    .vim
    filetype: apache
    
    <VirtualHost>
        ServerName www.me.org
        # ...
    </VirtualHost>
    .vim

=head1 BUGS

It doesn't work on Mac OS X! Check out L<https://rt.cpan.org/NoAuth/Bug.html?id=7316>

=head1 AUTHORS

Ian Langworth <ian@cpan.org>

=head1 SEE ALSO

L<Kwiki>, L<Text::VimColor>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__css/vim_mode.css__
pre.vim { margin-left: 1em }
.synComment    { color: #0000FF }
.synConstant   { color: #FF00FF }
.synIdentifier { color: #008B8B }
.synStatement  { color: #A52A2A ; font-weight: bold }
.synPreProc    { color: #A020F0 }
.synType       { color: #2E8B57 ; font-weight: bold }
.synSpecial    { color: #6A5ACD }
.synUnderlined { color: #000000 ; text-decoration: underline }
.synError      { color: #FFFFFF ; background: #FF0000 none }
.synTodo       { color: #0000FF ; background: #FFFF00 none }
