# $Id: Message.pm,v 1.9 2014-01-28 15:40:10 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Message::SerialiserBase;

use base Event::RPC::Message;

use strict;
use utf8;

sub UNIVERSAL::FREEZE {
    my ($object, $serialiser) = @_;
    my ($ref_type) = "$object" =~ /=(\w+)\(/;
    return $ref_type eq 'HASH'   ? [ $ref_type, [%{$object}] ] :
           $ref_type eq 'ARRAY'  ? [ $ref_type, [@{$object}] ] :
           $ref_type eq 'SCALAR' ? [ $ref_type,  ${$object}  ] :
           die "Unsupported reference type '$ref_type'"; 
}

sub UNIVERSAL::THAW {
    my ($class, $serialiser, $obj) = @_;
    return $obj->[0] eq 'HASH'   ? bless { @{$obj->[1]} }, $class :
           $obj->[0] eq 'ARRAY'  ? bless [ @{$obj->[1]} ], $class :
           $obj->[0] eq 'SCALAR' ? bless \   $obj->[1],    $class :
           die "Unsupported reference type '$obj->[0]'"; 
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Message::SerialiserBase - Base for some message classes

=head1 SYNOPSIS

  # Internal module. No documented public interface.

=head1 DESCRIPTION

This module implements universal FREEZE/THAW methodes
for JSON and CBOR based message format classes. Unfortunately
these modules can't take callbacks for these tasks but
require to pollute UNIVERSAL namespace for this, so when
loading several modules overriding these methodes by each
other throw warnings. This module exist just to prevent these.

=head1 AUTHORS

  Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
