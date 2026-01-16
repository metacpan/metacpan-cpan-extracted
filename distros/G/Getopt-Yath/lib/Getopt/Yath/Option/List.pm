package Getopt::Yath::Option::List;
use strict;
use warnings;

our $VERSION = '2.000007';

use Getopt::Yath::Util qw/decode_json/;

use parent 'Getopt::Yath::Option';
use Getopt::Yath::HashBase qw/<split_on/;

sub allows_list       { 1 }
sub allows_arg        { 1 }
sub requires_arg      { 1 }
sub allows_default    { 1 }
sub allows_autofill   { 0 }
sub requires_autofill { 0 }

sub notes { (shift->SUPER::notes(), 'Can be specified multiple times') }

sub is_populated { ${$_[1]} && @{${$_[1]}} }

sub get_clear_value {
    my $self = shift;
    return $self->_get___value(CLEAR(), @_) // [];
}

sub get_initial_value {
    my $self = shift;

    my @val;

    my $env = $self->from_env_vars;
    for my $name (@{$env || []}) {
        push @val => $ENV{$name} if defined $ENV{$name};
    }

    return \@val if @val;

    return undef if $self->{+MAYBE};
    return $self->_get___value(INITIALIZE()) // [];
}

sub add_value {
    my $self = shift;
    my ($ref, @val) = @_;
    return if $self->maybe && !@val;
    push @{$$ref} => @val;
}

sub normalize_value {
    my $self = shift;
    my (@input) = @_;

    if ($input[0] =~ m/^\s*\[.*\]\s*$/s) {
        my $out;
        local $@;
        unless (eval { local $SIG{__DIE__}; $out = decode_json($input[0]); 1 }) {
            my ($err) = split /[\n\r]+/, $@;
            $err =~ s{at \Q$INC{'Getopt/Yath/Util/JSON.pm'}\E line \d+\..*$}{};
            die "Could not decode JSON string: $err\n====\n$input[0]\n====\n";
        }
        return @$out;
    }

    my @output;
    if (my $on = $self->split_on) {
        @output = map { $self->SUPER::normalize_value($_) } map { split($on, $_) } @input;
    }
    else {
        @output = map { $self->SUPER::normalize_value($_) } @input;
    }

    return @output;
}

sub inject_default_long_examples  { qq{ '["json","list"]'}, qq{='["json","list"]'} }
sub inject_default_short_examples { qq{ '["json","list"]'}, qq{='["json","list"]'} }

sub default_long_examples  {
    my $self = shift;
    my %params = @_;

    my $list = $self->SUPER::default_long_examples(%params);
    push @$list => $self->inject_default_long_examples();
    return $list;
}

sub default_short_examples {
    my $self = shift;
    my %params = @_;

    my $list = $self->SUPER::default_long_examples(%params);
    push @$list => $self->inject_default_short_examples();
    return $list;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Option::List - Options that can take multiple values.

=head1 DESCRIPTION

Can take multiple values. C<--opt VAL> appends a value to the list. C<--no-opt>
will empty the list. If a C<split_on> parameter is provided then a single use
can set multiple values. For example if C<split_on> is set to C<,> then
C<--opt foo,bar> is provided, then C<foo> and C<bar> will both be added to the
list.

=head1 SYNOPSIS

    option copy_env => (
        short => 'e',
        type => 'List',
        description => "Specify environment variables to pass along with their current values",
        long_examples => [ ' HOME', ' SHELL' ],
        short_examples => [ ' HOME', ' SHELL' ],
    );

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
