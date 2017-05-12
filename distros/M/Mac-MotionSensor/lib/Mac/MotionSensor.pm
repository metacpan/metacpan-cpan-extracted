package Mac::MotionSensor;
use 5.008008;
use strict;
use warnings;
require XSLoader;

our $VERSION = '0.02';

XSLoader::load('Mac::MotionSensor', $VERSION);

sub new {
    my ($class) = @_;
    
    my $type = detect_sms() 
        or
    die "Couldn't detect a motion sensor";

    my $self = { type => $type };

    bless $self, $class;
    return $self;
}

sub x {
    return _get_x($_[0]->type);
}

sub y {
    return _get_y($_[0]->type);
}

sub z {
    return _get_z($_[0]->type);
}

sub raw_x {
    return _get_raw_x($_[0]->type);
}

sub raw_y {
    return _get_raw_y($_[0]->type);
}

sub raw_z {
    return _get_raw_z($_[0]->type);
}

sub type {
    return $_[0]->{type};
}

1;
__END__

=head1 NAME

Mac::MotionSensor - Access to your accelerometer

=head1 SYNOPSIS

  use Mac::MotionSensor;
  
  my $sensor = Mac::MotionSensor->new;

  # scaled output
  my $x = $sensor->x;
  my $y = $sensor->y;
  my $z = $sensor->z;

  # raw output
  $x = $sensor->raw_x;
  $y = $sensor->raw_y;
  $z = $sensor->raw_z;

  $sendor->type;

=head1 DESCRIPTION

This module wraps the UniMotion c library

All axis methods return a signed integer.

=head1 CAVEATS

UniMotion won't build against x86_64, I am working on this issue

=head1 SEE ALSO

The UniMotion C library

http://unimotion.sourceforge.net/

=head1 CONTRIBUTE

http://github.com/robinedwards/Mac-MotionSensor

=head1 AUTHOR

Robin Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

UniMotion is distributed under the LGPL license.

=cut
