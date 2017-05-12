package IO::Infiles;

use v5.8;
use strict;
use warnings;
use Fatal qw(open);

our $VERSION = '0.06';



sub inlinefiles {
        m/ ^__([A-Z]\w+)__\s*\n
           (.*?)
           (?=__[A-Z]\w+__\s*\n | \Z)
        /xsmgo;
}

sub import {
        local $_ = do{ local $/; open 0; <0>};
        (my $pack)= (caller 1)[3] =~ /^(.*::)/g ;
        my %files = inlinefiles;
        no strict 'refs' ; no warnings 'once';
        open *{$pack.$_} , '<', \$files{$_}   for keys(%files);
}


1;
__END__ 

=head1 NAME

IO::Infiles - Multiple handlers for multiple __END__-like tokens

=head1 SYNOPSIS

  use IO::Infiles;

  __END__
  end data 
  __FOO__
  foo data
  more
  __JOHN__
  john data

=head1 DESCRIPTION

This module adds more token sections at the end of your code. The
first token must be named __END__ ; as before, its data are available 
through the END handler. If there are more token sections with other names, 
handlers of the same name will all be pre-opened.


=head2 EXPORT

One read-only IO handler is exported for each token name.


=head1 TROUBLESHOOTING

The first token should be the __END__ token. If instead you use __DATA__ 
as the name for the first token, you will receive the warning "Attempt to free 
unreferenced scalar: SV 0x82ebdf0 during global destruction."  Rename 
your first token to __END__  if you want to silence this warning.


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=for nothing

This 'for nothing' section was written to silence test::pod::coverage

=head2  inlinefiles() 
An internal subroutine, the user should hold no interest.
=head2  open()
=cut

