package Export::Declare::Meta;
use strict;
use warnings;

use Carp qw/croak/;

my %STASH;

sub export       { $_[0]->{export} }
sub export_ok    { $_[0]->{export_ok} }
sub export_fail  { $_[0]->{export_fail} }
sub export_tags  { $_[0]->{export_tags} }
sub export_anon  { $_[0]->{export_anon} }
sub export_gen   { $_[0]->{export_gen} }
sub export_magic { $_[0]->{export_magic} }
sub package      { $_[0]->{package} }
sub vars         { $_[0]->{vars} }
sub menu         { $_[0]->{menu} }

sub new {
    my $class = shift;
    my ($pkg, %params) = @_;

    croak "$class constructor requires a package name" unless $pkg;

    my $self = $STASH{$pkg} ||= do {
        my $all     = [];
        my $fail    = [];
        my $default = [];
        bless(
            {
                export       => $default,
                export_ok    => $all,
                export_fail  => $fail,
                export_tags  => {DEFAULT => $default, ALL => $all, FAIL => $fail},
                export_anon  => {},
                export_gen   => {},
                export_magic => {},

                package => $pkg,
                vars    => 0,
                menu    => 0,
            },
            $class
        );
    };

    $self->inject_menu if $params{menu};
    $self->inject_vars if $params{vars};
    $self->inject_vars if $params{default} && !($self->{menu} || $self->{vars});

    return $self;
}

sub inject_menu {
    my $self = shift;
    return if $self->{menu}++;

    my $pkg = $self->{package};

    no strict 'refs';
    no warnings 'once';
    *{"$pkg\::IMPORTER_MENU"} = sub { %$self };
}

sub inject_vars {
    my $self = shift;
    return if $self->{vars}++;

    my $pkg = $self->{package};

    no strict 'refs';
    no warnings 'once';

    *{"$pkg\::EXPORT"}       = $self->{export};
    *{"$pkg\::EXPORT_OK"}    = $self->{export_ok};
    *{"$pkg\::EXPORT_TAGS"}  = $self->{export_tags};
    *{"$pkg\::EXPORT_ANON"}  = $self->{export_anon};
    *{"$pkg\::EXPORT_GEN"}   = $self->{export_gen};
    *{"$pkg\::EXPORT_FAIL"}  = $self->{export_fail};
    *{"$pkg\::EXPORT_MAGIC"} = $self->{export_magic};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Export::Declare::Meta - Meta-object to track a packages exports.

=head1 DESCRIPTION

This class represents all the export data for an exporter package. It can also
inject that data into C<@EXPORT> and similar variables, or into an
C<IMPORTER_MENU()> method as consumed by L<Importer>.

=head1 SYNOPSYS

    my $meta = Export::Declare::Meta->new($package);

    $meta->inject_vars;

    push @{$meta->export_ok} => qw/foo bar/;

=head1 METHODS

=over 4

=item $meta = $CLASS->new($pkg)

=item $meta = $CLASS->new($pkg, menu => 1, vars => 1, default => 1)

Get (or create) an instance for the specified C<$pkg>. If C<< menu => 1 >> is
used as an argument then C<IMPORTER_MENU()> will be injected. If C<< vars => 1
>> is used then C<@EXPORT> and similar vars will be set. If C<< default => 1 >>
is used then package cars will be injected, unless vars or menu have already
been injected.

=item $menta->inject_menu

This will inject the C<IMPORTER_MENU()> function.

=item $menta->inject_vars

This will associate C<@EXPORT> and friends with the meta-data.

=item $bool = $menta->vars

Check if vars have been injected.

=item $bool = $menta->menu

Check if C<IMPORTER_MENU()> has been injected.

=item $pkg = $menta->package

Get the package associated with the instance.

=item $arrayref = $menta->export

Get the arrayref listing DEFAULT exports.

=item $arrayref = $menta->export_ok

Get the arrayref listing ALL exports.

=item $arrayref = $menta->export_fail

Get the arrayref listing exports that may fail.

=item $hashref = $menta->export_tags

Get the hashref with all the tags.

=item $hashref = $menta->export_anon

Get the hashref with anonymous exports.

=item $hashref = $menta->export_gen

Get the hashref with generated exports.

=item $hashref = $menta->export_magic

Get the hashref with export magic.

=back

=head1 SOURCE

The source code repository for Export-Declare can be found at
F<http://github.com/exodist/Export-Declare/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
