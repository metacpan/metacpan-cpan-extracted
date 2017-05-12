package Gitosis::Config::Writer;
use Moose;
extends qw(Config::INI::Writer);

around preprocess_input => sub {
    my ( $next, $self, $input ) = @_;

    # let's go ahead and maintain backwards compat
    return $self->$next($input) unless blessed $input;

    confess q[Can't output non Gitosis::Config object]
      unless $input->isa('Gitosis::Config');

    my @output;

    push @output, 'gitosis' =>
      [ map { $_ => $input->$_ } qw(gitweb daemon loglevel repositories) ];

    for my $group ( $input->groups ) {
        push @output, 'group '
          . $group->name => [
            map { $_ => join ' ', @{ $group->$_ } }
              grep { $_ ne 'name' } keys %$group
          ];
    }

    for my $repo ( $input->repos ) {
        push @output, "repo $repo->{name}" =>
          [ map { $_ => $repo->{$_} } grep { $_ ne 'name' } keys %$repo ];
    }

    return \@output;
};

sub validate_input {
    my ( $self, $input ) = @_;

    my %seen;
    for ( my $i = 0 ; $i < $#$input ; $i += 2 ) {
        my ( $name, $props ) = @$input[ $i, $i + 1 ];
        $seen{$name} ||= {};

        Carp::croak "illegal section name '$name'"
          if $name =~ /(?:\n|\s;|^\s|\s$)/;

        for ( my $j = 0 ; $j < $#$props ; $j += 2 ) {
            my $property = $props->[$j];
            my $value    = $props->[ $j + 1 ];

            Carp::croak "property name '$property' contains illegal character"
              if $property =~ /(?:\n|\s;|^\s|=$)/;

            Carp::croak "value for $name.$property contains illegal character"
              if defined $value and $value =~ /(?:\n|\s;|^\s|\s$)/;

            if ( $seen{$name}{$property}++ ) {
                Carp::croak "multiple assignments found for $name.$property";
            }
        }
    }
}

no Moose;
1;
__END__

__END__

=head1 NAME

Gitosis::Config::Writer - A class to output a valid gitosis.conf file

=head1 SYNOPSIS

	use Gitosis::Config::Writer;
	Gitosis::Config::Writer->write_string( $cfg );

=head1 DESCRIPTION

The Gitosis::Config::Writer class extends Config::INI::Writer 

=head1 METHODS

All methods are exactly the same as Config::INI::Writer except as documented
below.

=head2 validate_input ($input)

=head2 preprocess_input ($input)

=head1 DEPENDENCIES

Moose, Config::INI::Writer

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (chris@prather.org)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
