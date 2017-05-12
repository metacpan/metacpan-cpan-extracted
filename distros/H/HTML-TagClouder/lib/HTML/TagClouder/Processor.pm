# $Id: /local/perl/HTML-TagClouder/trunk/lib/HTML/TagClouder/Processor.pm 11406 2007-05-23T10:17:09.023599Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package HTML::TagClouder::Processor;
use strict;
use warnings;
use Class::C3;
use base qw(Class::Accessor::Fast);

sub new { shift->next::method({ @_ }) }

sub process {}

1;

__END__

=head1 NAME

HTML::TagClouder::Processor - Tag Processor Base Class

=head1 METHODS

=head2 new

=head2 process

=cut
