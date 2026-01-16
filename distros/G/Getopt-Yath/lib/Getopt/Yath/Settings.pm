package Getopt::Yath::Settings;
use strict;
use warnings;

our $VERSION = '2.000007';

use Carp();

use Getopt::Yath::Settings::Group;

use Getopt::Yath::Util qw/decode_json decode_json_file/;

sub new {
    my $class = shift;
    my $self = @_ == 1 ? $_[0] : { @_ };

    bless($self, $class);

    Getopt::Yath::Settings::Group->new($_) for values %$self;

    return $self;
}

sub maybe {
    my $self = shift;
    my ($group, $opt, $default) = @_;

    return $default unless $self->check_group($group);

    my $g = $self->$group;

    return $default unless $g->check_option($opt);

    return $g->$opt // $default;
}

sub check_group { $_[0]->{$_[1]} // 0 }

sub group {
    my $self = shift;
    my ($group, $vivify) = @_;

    return $self->{$group} if $self->{$group};

    return $self->{$group} = Getopt::Yath::Settings::Group->new()
        if $vivify;

    Carp::confess("The '$group' group is not defined");
}

sub create_group {
    my $self = shift;
    my ($name, @vals) = @_;

    return $self->{$name} = Getopt::Yath::Settings::Group->new(@vals == 1 ? $vals[0] : { @vals });
}

sub delete_group {
    my $self = shift;
    my ($name) = @_;

    delete $self->{$name};
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $this = shift;

    my $group = $AUTOLOAD;
    $group =~ s/^.*:://g;

    return if $group eq 'DESTROY';

    Carp::confess("Method $group() must be called on a blessed instance") unless ref($this);

    $this->group($group);
}

sub FROM_JSON_FILE {
    my $class = shift;
    my ($file, %params) = @_;

    my $data = decode_json_file($file, %params);
    $class->new($data);
}

sub FROM_JSON {
    my $class = shift;
    my ($json) = @_;

    my $data = decode_json($json);
    $class->new($data);
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

Getopt::Yath::Settings - Representation of parsed command line options.

=head1 DESCRIPTION

When you parse command line options using L<Getopt::Yath> an instance of this
data structure is included in the returnd structure.

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

=item $group = $settings->GROUP

If a group exists, there will be a ->GROUP method for it.

=item $value = $settings->maybe($group_name, $option_name)

=item $value = $settings->maybe($group_name, $option_name, $default_value)

If the group and option both exist and are defined return the value, otherwise
return the default.

=item $group = $settings->check_group($group_name)

Check if the group exists, if so return it.

=item $group = $settings->group($group_name)

=item $group = $settings->group($group_name, $vivify)

Get the specified group. If $vivify is true it will create the group if it does
not already exist.

Throws an exception if the group does not exist and vivify is not specified.

=item $group = $settings->create_group($group_name)

=item $group = $settings->create_group($group_name, %group_construction_args)

=item $group = $settings->create_group($group_name, \%group_construction_args)

Create or replace the specified group.

=item $group = $settings->delete_group($group_name)

Delete the specified group. Also returns a reference to the now deleted group.

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
