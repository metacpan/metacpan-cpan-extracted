#!/usr/bin/perl -w
use strict;

my $VERSION = '0.08';

#----------------------------------------------------------
# Loader Variables

my $BASE;
BEGIN {
    $BASE = '../../cgi-bin';
}

#----------------------------------------------------------
# Library Modules

use lib ( "$BASE/lib", "$BASE/plugins" );

use HTML::Entities;

use Labyrinth::Globals;
use Labyrinth::Variables;

#----------------------------------------------------------
# Variables

my $config = "$BASE/config/settings.ini";

#----------------------------------------------------------
# Code

Labyrinth::Globals::LoadSettings($config);
Labyrinth::Globals::DBConnect();

$CODE = $settings{icode};
die "No conference code is set\n"   unless($CODE);

my $count = 0;
my @rs = $dbi->GetQuery('hash','NoSurvey',{where=>''});
for my $row (@rs) {
    next    if($row->{email} =~ /example.com/);

    $row->{name} = decode_entities($row->{realname});
    print join(",",map {$row->{$_}} qw(userid name email code)) . "\n";
    $count++;
}

print "Outstanding: $count\n";

__END__

=head1 NAME

nosurvey.pl - script to list the non-respondees of the main conference survey.

=head1 DESCRIPTION

Lists those attendees who have yet to respond to the main conference survey.
Includes the keycode and validation id, to be given to users if they have lost
their email with the auto-login URL.

=head1 USAGE

  nosurvey.pl

=head1 SEE ALSO

L<Labyrinth>

L<http://yapc-surveys.org>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug report and/or patch via RT [1], or raise
an issue or submit a pull request via GitHub [2]. Note that it helps
immensely if you are able to pinpoint problems with examples, or supply a
patch.

[1] http://rt.cpan.org/Public/Dist/Display.html?Name=Labyrinth-Plugin-Survey
[2] http://github.com/barbie/labyrinth-plugin-survey

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

Barbie, <barbie@cpan.org>
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT

  Copyright (C) 2006-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
