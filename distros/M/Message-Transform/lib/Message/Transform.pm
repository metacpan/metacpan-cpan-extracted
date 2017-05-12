package Message::Transform;
{
  $Message::Transform::VERSION = '1.132260';
}

use strict;use warnings;
require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(mtransform);

sub mtransform {
    my ($message, $transform) = @_;
    die 'Message::Transform::mtransform: two HASH references required'
        if  scalar @_ < 2 or
            scalar @_ > 2 or
            not ref $message or
            not ref $transform or
            ref $message ne 'HASH' or
            ref $transform ne 'HASH';

    return _mtransform($message, $transform);
}

sub _special {
    my ($message, $transform) = @_;
    my $orig_transform = $transform; #in case we need to bail out
    substr($transform, 0, 8, '');
    if($transform =~ /^s\//) {
        substr($transform, 0, 2, '');
        my $ret;
        eval "\$ret = $transform;";
        return $ret;
    }
    return $orig_transform;
}

sub _mtransform {
    my ($message, $transform) = @_;
    foreach my $t (keys %$transform) {
        if(ref $transform->{$t}) {  #shallow copy if transform is reference
            $message->{$t} = $transform->{$t};
        } else {    #scalar; perhaps something fancy
            if(substr($transform->{$t}, 0, 8) eq ' special') { #special handling
                $message->{$t} = _special($message, $transform->{$t});
            } else {
                $message->{$t} = $transform->{$t};
            }
        }
    }
}
1;
__END__

=head1 NAME

Message::Transform - Fast, simple message transformations

=head1 SYNOPSIS

    use Message::Transform qw(mtransform);

    my $message = {a => 'b'};
    mtransform($message, {x => 'y'});
    #$message contains {a => 'b', x => 'y'}

    my $message = {a => 'b'};
    mtransform($message, {c => {d => 'e'}});
    #$message contains {a => 'b', c => {d => 'e'}}

    my $message = {a => 'b'};
    mtransform($message, {x => ' specials/$message->{a}'});
    #$message contains {a => 'b', x => 'b'}

=head1 DESCRIPTION

This is a very very light-weight and fast library that does some basic but
reasonably powerful message substitutions.

=head1 FUNCTION

=head2 mtransform($message, $transform);

Takes two and only two arguments, both HASH references.

=head1 SEE ALSO

=head1 TODO

More special handling.

Recursive transforms.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2013 Dana M. Diederich. All Rights Reserved.

=head1 AUTHOR

Dana M. Diederich <diederich@gmail.com>

=cut
