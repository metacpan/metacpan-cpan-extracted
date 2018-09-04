package Email::Sender::Transport::Redirect::Recipients;

use strict;
use warnings;
use Moo;
use Email::Valid;
use Types::Standard qw/ArrayRef Str/;

=head1 NAME

Email::Sender::Transport::Redirect::Recipients - handle email address redirect replacements

=head1 SYNOPSIS

This is a class used internally by
L<Email::Sender::Transport::Redirect> and shouldn't be used directly.

  my $rec = Email::Sender::Transport::Redirect::Recipients->new($string_or_hashref);

  print $rec->to;
  print Dumper($rec->exclude);
  print $rec->replace('myemail@example');

=head1 CONSTRUCTOR

=head2 BUILDARGS

=head2 new($string_or_hashref)

Either a single email as string, or an hashref which are used to
initialize the accessors (see above). If a string is provided, then
just C<to> will be set and no exclusions are set.

=head1 ACCESSORS

=head2 to

The main, required email address to use as a redirect.

=head2 exclude

An arrayref of emails or wildcard expressions. E.g.

 [ 'mail@example.org', '*@example.org', 'racke@*' ]

These emails will not get redirected.

=head1 METHODS

=head2 replace($string)

Main method. When a string is passed, it's checked against the
exclusion list. If there is a match, the address passed as argument
will be returned, otherwise the C<to> address set in the object will
be returned.

=cut


has to => (is => 'ro', isa => Str, required => 1);
has exclude => (is => 'ro', isa => ArrayRef[Str], default => sub { [] });

sub BUILDARGS {
    my ($class, @args) = @_;
    die "Only one argument is supported!" unless @args == 1;
    my $arg = shift @args;
    if (my $kind = ref($arg)) {
        if ($kind eq 'HASH') {
            my %hash = %$arg;
            foreach my $k (keys %hash) {
                die "Extra argument $k" unless $k eq 'to' || $k eq 'exclude';
            }
            return \%hash;
        }
        die "Argument must be an hashref with to and exclude keys, you passed a $kind";
    }
    else {
        return { to => $arg };
    }
}

has excludes_regexps => (is => 'lazy', isa => ArrayRef);

sub _build_excludes_regexps {
    my $self = shift;
    my @out;
    foreach my $exclusion (@{$self->exclude}) {
        if ($exclusion =~ m/\*/) {
            my $re = $exclusion;
            # http://blogs.perl.org/users/mauke/2015/08/converting-glob-patterns-to-regular-expressions.html
            $re =~ s{(\W)}{
                $1 eq '?' ? '.' :
                $1 eq '*' ? '.*' :
                '\\' . $1
              }eg;
            push @out, qr{$re};
        }
        elsif (my $address = Email::Valid->address($exclusion)) {
            push @out, qr{\Q$address\E};
        }
        else {
            die "Exclusion contains an invalid string: $exclusion, nor a wildcard, nor a valid address: $exclusion";
        }
    }
    return \@out;
}



sub replace {
    my ($self, $mail) = @_;
    if ($mail) {
        if (my @exclusions = @{$self->excludes_regexps}) {
            # an alternate approach could be Email::Address to allow multiple addresses
            if (my $address = Email::Valid->address($mail)) {
                my $real = $address . ''; # stringify
                foreach my $re (@exclusions) {
                    # print "Checking $real against $re\n";
                    if ($real =~ m/\A$re\z/) {
                        # print "Found, returning $real\n";
                        return $real;
                    }
                }
            }
        }
    }
    # fall back
    # print "Falling back\n";
    return $self->to;
}

1;
