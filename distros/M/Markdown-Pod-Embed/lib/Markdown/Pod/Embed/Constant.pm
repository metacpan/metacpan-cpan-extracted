#
#  This file is part of Markdown::Pod::Embed.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package Markdown::Pod::Embed::Constant;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION @ISA @EXPORT $OPTION_HR $PANDOC_EXE
    $PANDOC_CMD_MD2TEXT_CR);
use warnings;


#  External packages
#
use Config;
use Exporter;
use File::Spec;


#  Version and exports
#
$VERSION='1.012';
@ISA=qw(Exporter);
@EXPORT=qw($OPTION_HR $PANDOC_EXE $PANDOC_CMD_MD2TEXT_CR);


#  Default processor options
#
$OPTION_HR={dialect => 'GitHub'};


#  Find Pandoc when it is available for plain-text rendering
#
$PANDOC_EXE='';
foreach my $dir (File::Spec->path()) {
    foreach my $name (qw(pandoc pandoc.exe)) {
        my $fn=File::Spec->catfile($dir, $name);
        if (-f $fn && -x $fn) {
            $PANDOC_EXE=$fn;
            last;
        }
    }
    last if $PANDOC_EXE;
}


#  Construct the Markdown-to-text Pandoc command
#
$PANDOC_CMD_MD2TEXT_CR=sub {
    return [shift(), '-f', 'gfm', '-t', 'plain', shift()];
};


#  Done
#
1;
__END__

=begin markdown

# NAME

Markdown::Pod::Embed::Constant - internal defaults for Markdown::Pod::Embed

# DESCRIPTION

This module supplies the default Markdown dialect and discovers Pandoc for
plain-text rendering. It is used by `Markdown::Pod::Embed` and its command-line
utility; applications should configure the processor through its constructor.

# SEE ALSO

`Markdown::Pod::Embed`, `markpod`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=end markdown


=head1 NAME

Markdown::Pod::Embed::Constant - internal defaults for Markdown::Pod::Embed


=head1 DESCRIPTION

This module supplies the default Markdown dialect and discovers Pandoc for
plain-text rendering. It is used by C<Markdown::Pod::Embed> and its command-line
utility; applications should configure the processor through its constructor.


=head1 SEE ALSO

C<Markdown::Pod::Embed>, C<markpod>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
