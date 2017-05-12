sub one {
  print "one\n";
}

=head1 two

Prints C<two> and returns 2

Its implementation is:

  sub twoexample {
    2*print "two\n";
  }

=cut

sub two {
  2*print "two\n";
}

my $x = "sub six { 6*print \"six\n\"; }\n";
my $z = 'sub seven { 7*print "seven\n"; }\n';

sub three {
  3*print "three\n";
}

# Commented function
#sub five {
#  5*print "five\n";
#}

__END__

sub four {
  4*print "four\n";
}

=head1 DESCRIPTION

This is an example for being used with the C<include>
feature
