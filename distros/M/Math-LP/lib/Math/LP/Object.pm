package Math::LP::Object;
use strict;
use fields qw();

sub new { # constructs a new object
    my $pkg = shift;
    no strict 'refs';
    my Math::LP::Object $this = fields::new($pkg);
    my %arg = @_;
    while(my($k,$v) = each %arg) { $this->{$k} = $v; }
    $this->initialize();
    return $this;
}
sub initialize { # override in derived classes
    1; 
}
sub croak { # trace an error coming from outside the Math::LP functions
    shift if defined(ref $_[0]); # invoked on object
    for(my $i = 1; $i < 9999; ++$i) { # 9999 is an arbitrary upper limit
	my ($cpkg,$cfile,$cline,$csub) = caller($i);
	if($cpkg !~ /^Math::LP/) { # found the evil caller
	    my $msg = join '', @_;
	    chomp $msg;
	    die $msg, " in $csub at line $cline of $cfile.\n";
	}
    }
}

1;

__END__

=head1 NAME

Math::LP::Object - base class for objects in the Math::LP family

=head1 SYNOPSIS

    package Math::LP::Foo; # a new member Foo in the family

    # derive Foo from Object
    use Math::LP::Object;
    use base qw(Math::LP::Object);
    use fields qw(foo bar);

    sub initialize {
        my Math::LP::Foo $this = shift;
        # put Foo specific initialization code here
	# ...
	return 1;
    }

    # And add Foo-specific methods
    # ...

=head1 DESCRIPTION

Math::LP::Object provides the following methods to classes derived from it:

=over 4

=item new()

Returns a new object, blessed in the package which it was called for. The
returned object is a pseudo-hash, with fields specified using the fields
pragma.

new() optionally accepts a hash of initial values of the data fields.
After these values have been set, initialize() is called on the object.
Specific initialization code for the derived class is thus to be put in
the initialize() function of the derived class.

=item croak($msg)

Dies with an error message, adding info on the last caller outside
the Math::LP family.

croak() can be invoked both as a method and a package function.

=back

=head1 KNOWN PROBLEMS

The fields pragma is used here, which makes multiple inheritance
impossible when other base classes also use the fields pragma
(see L<fields>). For this reason, Math::LP::LinearCombination
and Math::LP::Variable are NOT derived from Math::LP::Object, and
as a result have no access to the functionality the latter provides.

=head1 SEE ALSO

L<base>, L<fields>

=head1 AUTHOR

Wim Verhaegen E<lt>wimv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright(c) 2000-2001 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

=cut
