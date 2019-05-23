package Log::Log4perl::Layout::JSON::Readable;

use strict;
use warnings;
use parent 'Log::Log4perl::Layout::JSON';
our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: JSON layout, but some fields always come first

use Class::Tiny +{
    first_fields => sub { [qw(time pid level)] },
};


sub BUILDARGS {
    my ($class, @etc) = @_;
    # the parent class does not have a BUILDARGS, but it may get one
    # in the future, let's handle both cases
    my $args = $class->maybe::next::method(@etc) || $etc[0];

    if (my $first_fields = delete $args->{first_fields}) {
        $args->{first_fields} = [
            grep { length }
                map { my $v = $_; $v =~ s/\s+//g; $v }
                split /\s*,\s*/,
            $first_fields->{value},
        ];
    }

    return $args;
}

# HACK!! the parent class C<warn>s when it sees an argument it doesn't
# expect. To prevent that, we consume it first
sub BUILDALL {
    my ($self, $args, @etc) = @_;

    if (my $first_fields = delete $args->{first_fields}) {
        $self->first_fields($first_fields);
    }

    return $self->next::method($args,@etc);
}

sub render {
    my $self = shift;

    my $json = $self->SUPER::render(@_);

    if (my $first_fields = $self->first_fields) {
        for my $key (reverse @{$first_fields}) {
            _move_field_first(\$json, $key);
        }
    }

    return $json;
}

sub _move_field_first {
    my ($json_ref, $key) = @_;
    ${$json_ref} =~ s/^{(.+?),("$key":".+?")/\{$2,$1/;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Log4perl::Layout::JSON::Readable - JSON layout, but some fields always come first

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

Example configuration:

    log4perl.appender.Example.layout = Log::Log4perl::Layout::JSON::Readable
    log4perl.appender.Example.layout.field.message = %m{chomp}
    log4perl.appender.Example.layout.field.category = %c
    log4perl.appender.Example.layout.field.time = %d
    log4perl.appender.Example.layout.field.pid = %P
    log4perl.appender.Example.layout.field.level = %p
    log4perl.appender.Example.layout.canonical = 1
    log4perl.appender.Example.layout.first_fields = time, pid, level

=head1 DESCRIPTION

This layout works just like L<< C<Log::Log4perl::Layout::JSON> >>, but
it always prints some fields first, even with C<< canonical => 1 >>.

=for Pod::Coverage first_fields

The fields to print first are set via the C<first_fields> attribute,
which is a comma-separated list of field names (defaults to C<time,
pid, level>, like in the synopsis).

So, instead of:

    {"category":"App.Minion.stats","level":"TRACE","message":"Getting metrics","pid":"6689","time":"2018-04-04 13:57:23,990"}

you get:

    {"time":"2018-04-04 13:57:23,990","pid":"6689","level":"TRACE","category":"App.Minion.stats","message":"Getting metrics"}

which is more readable (e.g. for the timestamp) and usable (e.g. for
the pid).

=head1 AUTHORS

=over 4

=item *

Johan Lindstrom <Johan.Lindstrom@broadbean.com>

=item *

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
