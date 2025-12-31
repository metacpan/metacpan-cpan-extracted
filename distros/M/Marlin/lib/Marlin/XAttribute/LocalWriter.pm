use 5.008008;
use strict;
use warnings;

package Marlin::XAttribute::LocalWriter;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.010000';

use Eval::TypeTiny ();
use Role::Tiny;

after canonicalize_is => sub {
	my $me = shift;
	
	if ( not ref $me->{':LocalWriter'} ) {
		my $method_name = $me->{':LocalWriter'};
		$me->{':LocalWriter'} = { method_name => $method_name, try => !!0 };
	}

	if ( $me->{':LocalWriter'}{method_name} eq 1 ) {
		$me->{':LocalWriter'}{method_name} = sprintf(
			'%s%s',
			$me->{slot} =~ /^_/ ? '_local' : 'local_',
			$me->{slot},
		);
	}
	
	# If user has requested an local writer method that has the same name
	# as a normal writer method, assume they don't want the normal one!
	my $method_name = $me->{':LocalWriter'}{method_name};
	for my $thing ( qw/ writer / ) {
		delete $me->{$thing} if defined $me->{$thing} && $me->{$thing} eq $method_name;
	}
};

after install_accessors => sub {
	my $me = shift;
	
	my $pkg = $me->{package};
	my $method_name = $me->{':LocalWriter'}{method_name};
	my $guard_class = $me->_guard_class;
	
	my $coderef = $me->inline_to_coderef( 'local writer' => qq{
		my \$self = shift;
		my \$guard;
		
		@{[ $me->_croaker ]}("$method_name cannot be called in void context") unless defined wantarray;
		
		if ( @{[ $me->inline_predicate('$self') ]} ) {
			my \$old_value = do { @{[ $me->inline_reader('$self') ]} };
			\$guard = $guard_class->new( sub { @{[ $me->inline_writer('$self', '$old_value') ]} } );
		}
		else {
			\$guard = $guard_class->new( sub { @{[ $me->inline_clearer('$self') ]} } );
		}
		
		if ( \@_ ) {
			@{[ $me->inline_writer('$self', '$_[0]') ]}
		}
		else {
			@{[ $me->inline_clearer('$self') ]}
		}
		
		return \$guard;
	} );
	
	$me->install_coderef( $method_name, $coderef );
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::XAttribute::LocalWriter - Marlin attribute extension for localizing attribute values.

=head1 SYNOPSIS

  package Local::Person {
    use Marlin::Util -all;
    use Types::Common -types;
    use Marlin
      name => {
        required       => true,
        isa            => Str,
        ':LocalWriter' => 'temp_name',
      };
  }
  
  my $bob = Local::Person->new( name => 'Bob' );
  say $bob->name;  # "Bob"
  
  {
    my $guard = $bob->temp_name( 'Robert' );
    say $bob->name;  # Robert
  }
  
  say $bob->name;  # "Bob"

=head1 DESCRIPTION

The following are spiritually similar:

  {
    my $guard = $bob->temp_name( "Robert" );
    ...;
  }
  
  {
    local $bob->{name} = "Robert";
    ...;
  }

However, the local writer method will honour type constraints, triggers,
etc.

Calling C<< $bob->temp_name() >> with no parameters is equivalent to
doing C<< delete local >>.

Note that the C<< $guard >> which is returned by the method is where
a lot of the magic happens. When it goes out of scope, it restores the
original value.

If you set C<< ':LocalWriter' => 1 >>, this is a shortcut for
C<< ':LocalWriter' => "_local$attrname" >> if your attribute's name
starts with an underscore, and C<< ':LocalWriter' => "local_$attrname" >>
otherwise.

This extension makes no changes to your constructor.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟🐟
