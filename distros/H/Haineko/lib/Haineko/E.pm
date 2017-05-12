package Haineko::E;
use strict;
use warnings;
use Class::Accessor::Lite;

my $rwaccessors = [
    'file',     # (String) Path to the module file which an error occurred.
    'line',     # (Integer) line number
    'mesg',     # (ArrayRef) Reply messages
];
my $roaccessors = [];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );

sub new {
    my $class = shift;
    my $argvs = shift || return undef;
    my $param = {
        'file' => undef,
        'line' => undef,
        'mesg' => [],
    };
    chomp $argvs;

    if( $argvs =~ m|\A(.+)\s+at\s+(.+)\s+line\s+(\d+)[.]\z| ) {
        # Error message at /path/to/file line 22.
        $param->{'file'} = $2;
        $param->{'line'} = $3;
        $param->{'mesg'} = __PACKAGE__->p( $1 );

    } else {
        my $c = [ caller ];
        $param->{'file'} = $c->[1];
        $param->{'line'} = $c->[2];
        $param->{'mesg'} = __PACKAGE__->p( $1 );
    }
    return bless $param, __PACKAGE__;
}

sub p {
    my $class = shift;
    my $argvs = shift || return [];
    my $error = [];

    chomp $argvs;
    if( $argvs =~ m|\A(Can't locate .+\s)(in\s[@]INC\s.+)\z| ) {
        # Can\'t locate Haineko/SMTPD/Relay/Neko.pm in @INC (@INC contains: /tmp...)
        $error = [ $1, $2 ];

    } else {
        $error = [ split( "\n", $argvs ) ];
    }

    for my $e ( @$error ) {
        $e =~ s|\A\s*||; 
        $e =~ s|\s*\z||; 
    }

    return $error;
}

sub message {
    my $self = shift;
    my $mesg = q();

    return q() unless scalar @{ $self->{'mesg'} };
    $mesg .= join( "\n", @{ $self->{'mesg'} } );
    $mesg .= sprintf( " at %s", $self->{'file'} );
    $mesg .= sprintf( " line %d.", $self->{'line'} );

    return $mesg;
}

sub text {
    my $self = shift;
    return q() unless scalar @{ $self->{'mesg'} };
    return join( ' ', @{ $self->{'mesg'} } );
}

1;
__END__
=encoding utf8

=head1 NAME

Haineko::E - Convert error message to an object

=head1 DESCRIPTION

Haineko::E provide methods for converting an error message of perl such as
"error at /path/to/file.pl line 2." to an object.

=head1 SYNOPSIS

    use Haineko::E;
    eval { die 'Nyaaaaaaa!!!!' };
    my $e = Haineko::E->new( $@ );

=head1 CLASS METHODS

=head2 B<new( I<Error Message> )>

new() is a constructor of Haineko::E

    use Haineko::E;
    eval { die 'Hardest' };
    my $e = Haineko::E->new( $@ );

    print $e->file;             # /path/to/file.pl
    print $e->line;             # 2
    print for @{ $e->mesg };    # Hardest

=head1 INSTANCE METHODS

=head2 B<message()>

message() returns whole error message as a text (scalar value).

    use Haineko::E;
    eval { die 'Hard 2' };
    my $e = Haineko::E->new( $@ );

    print $e->message;          # Hard 3 at /path/to/file.pl line 2.

=head2 B<text()>

text() returns error message part only.

    use Haineko::E;
    eval { die 'Hard 3' };
    my $e = Haineko::E->new( $@ );

    print $e->text;             # Hard 3

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
