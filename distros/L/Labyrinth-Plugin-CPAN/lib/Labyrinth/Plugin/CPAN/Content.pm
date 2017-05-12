package Labyrinth::Plugin::CPAN::Content;

use strict;
use warnings;

our $VERSION = '3.56';

=head1 NAME

Labyrinth::Plugin::CPAN::Content - Additional content for CPAN.

=head1 DESCRIPTION

The functions contain herein are for CPAN and CPAN Testers related page content.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Support;
use Labyrinth::Variables;

use JSON;
use WWW::Mechanize;

#----------------------------------------------------------------------------
# Variables

# this should be a config option
# $settings{iheart_random} = 'http://iheart.cpantesters.org/home/random';

#----------------------------------------------------------
# Content Management Subroutines

=head1 CONTENT MANAGEMENT FUNCTIONS

=over 4

=item GetSponsor

Gets a random sponsor from the I <3 CPAN Testers website.

=back

=cut

sub GetSponsor {
    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );
    eval { $mech->get( $settings{iheart_random} ) };
    return if($@ || !$mech->success() || !$mech->content());

    my $json = $mech->content();
    my $data = decode_json($json);

    return unless($data);

    $tvars{sponsor} = {
        title => $data->[0]->{links}[0]{title},
        image => $data->[0]->{links}[0]{image},
        body  => $data->[0]->{links}[0]{body},
        href  => $data->[0]->{links}[0]{href},
        url   => $data->[0]->{links}[0]{href}
    };

    $tvars{sponsor}{url} =~ s!^https?://(?:www\.)?([^/]+).*!$1!  if($tvars{sponsor}{url});
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2016 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
