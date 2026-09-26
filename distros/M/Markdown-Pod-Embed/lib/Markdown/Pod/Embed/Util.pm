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
package Markdown::Pod::Embed::Util;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION @ISA @EXPORT $QUIET $VERBOSE $DEBUG);
use warnings;


#  External packages
#
use Carp qw(croak);
use Data::Dumper qw(Dumper);
use Exporter;


#  Version and exports
#
$VERSION='1.012';
@ISA=qw(Exporter);
@EXPORT=qw(err msg debug verbose slurp blurp Dumper quiet_enable
    verbose_enable debug_enable);


#  Package state
#
$QUIET=0;
$VERBOSE=0;
$DEBUG=0;


#  Done
#
1;


#===================================================================================================

sub err {

    croak(sprintf(shift(), @_));

}


sub msg {

    print STDERR sprintf(shift(), @_), "\n" unless $QUIET;
    return undef;

}


sub debug {

    msg(@_) if $DEBUG;
    return undef;

}


sub verbose {

    msg(@_) if $VERBOSE;
    return undef;

}


sub quiet_enable {

    $QUIET=shift();
    return $QUIET;

}


sub verbose_enable {

    $VERBOSE=shift();
    return $VERBOSE;

}


sub debug_enable {

    $DEBUG=shift();
    return $DEBUG;

}


sub slurp {


    #  Read the complete file without changing line endings
    #
    my ($fn)=@_;
    open(my $input_fh, '<', $fn) ||
        err('unable to read %s: %s', $fn, $!);
    binmode($input_fh);
    local $/;
    my $text=<$input_fh>;
    close($input_fh) ||
        err('unable to close %s: %s', $fn, $!);
    return defined($text) ? $text : '';

}


sub blurp {


    #  Write the complete file without changing line endings
    #
    my ($fn, $text)=@_;
    open(my $output_fh, '>', $fn) ||
        err('unable to write %s: %s', $fn, $!);
    binmode($output_fh);
    my $write_ok=print {$output_fh} $text;
    $write_ok || err('unable to write %s: %s', $fn, $!);
    close($output_fh) ||
        err('unable to close %s: %s', $fn, $!);
    return 1;

}
__END__

=begin markdown

# NAME

Markdown::Pod::Embed::Util - internal file and diagnostic helpers

# DESCRIPTION

This module contains the small file, message and diagnostic helpers used by
`Markdown::Pod::Embed`. It is an implementation module rather than a supported
application interface.

# SEE ALSO

`Markdown::Pod::Embed`, `markpod`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=end markdown


=head1 NAME

Markdown::Pod::Embed::Util - internal file and diagnostic helpers


=head1 DESCRIPTION

This module contains the small file, message and diagnostic helpers used by
C<Markdown::Pod::Embed>. It is an implementation module rather than a supported
application interface.


=head1 SEE ALSO

C<Markdown::Pod::Embed>, C<markpod>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
