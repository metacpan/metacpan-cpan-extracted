package Getopt::Yath::Settings::Group;
use strict;
use warnings;

our $VERSION = '2.000007';

use Carp();

sub new {
    my $class = shift;
    my $self = (@_ != 1) ? { @_ } : $_[0];

    return bless($self, $class);
}

sub all { return %{$_[0]} }

sub check_option { exists($_[0]->{$_[1]}) ? 1 : 0 }

sub option :lvalue {
    my $self = shift;
    my ($option, @vals) = @_;

    Carp::confess("Too many arguments for option()") if @vals > 1;
    Carp::confess("The '$option' option does not exist") unless exists $self->{$option};

    ($self->{$option}) = @vals if @vals;

    return $self->{$option};
}

sub create_option {
    my $self = shift;
    my ($name, $val) = @_;

    $self->{$name} = $val;

    return $self->{$name};
}

sub option_ref {
    my $self = shift;
    my ($name, $create) = @_;

    Carp::confess("The '$name' option does not exist") unless $create || exists $self->{$name};

    return \($self->{$name});
}

sub delete_option {
    my $self = shift;
    my ($name) = @_;

    delete $self->{$name};
}

sub remove_option {
    my $self = shift;
    my ($name) = @_;
    delete ${$self}->{$name};
}

our $AUTOLOAD;
sub AUTOLOAD : lvalue {
    my $this = shift;

    my $option = $AUTOLOAD;
    $option =~ s/^.*:://g;

    return if $option eq 'DESTROY';

    Carp::confess("Method $option() must be called on a blessed instance") unless ref($this);

    $this->option($option, @_);
}

sub TO_JSON {
    my $self = shift;
    return {%$self};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Settings::Group - Representation of an option group.

=head1 DESCRIPTION

This is used by L<Getopt::Yath::Settings> to represent parsed group settings.

=head1 SYNOPSIS

    my $parsed = parse_options(\@ARGV, ...);

    my $settings = $parsed->settings;

    my $value = $settings->GROUP->OPTION;

    # Or

    my $value = $settings->group('GROUP')->option('OPTION');

    # Or

    my $value = $settings->maybe('GROUP' => 'OPTION', $default);


    if ($group = $settings->check_group('GROUP')) {
        # We have the specified group
    }

=head1 METHODS

=over 4

=item %options = $group->all

Get all options, key/value pairs.

=item $bool = $group->check_option($option_name)

Check if an option exists.

=item $value = $group->option($option_name)

=item $value = $group->option($option_name, $value)

=item $group->option($option_name) = $value

Get/set an option.

=item $group->create_option($option_name, $value)

Create the specified option.

=item $ref = $group->option_ref($option_name)

=item $ref = $group->option_ref($option_name, $create)

Get a reference to the value of the specified option. Optionally create it if
it does not exist.

    my $ref = $group->option_ref('foo');
    $$ref = 'I am setting the option value';

=item $value = $group->delete_option($option_name)

=item $value = $group->remove_option($option_name)

Delete an option, returning the value it used to have.

=back

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
