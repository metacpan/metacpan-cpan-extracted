package Hook::Heckle;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01.01';

our $DEBUG = 0;

use Class::Maker;
	
	Class::Maker::class
	{
		public =>
		{
			string => [qw( victim context )],
			
			ref => [qw( pre post )],
			
			array => [qw( result )],
		}		
	};
	
	sub __pre
	{
		my $this = shift;
	}

	sub __post
	{
		my $this = shift;
	}

	sub _preinit : method
	{
		my $this = shift;
		
			$this->context( 'main' );
			
			$this->pre( sub { } );
			
			$this->post( sub { } );
	}

	sub _postinit : method
	{		
		my $this = shift;

			my $method = sprintf '%s::%s', $this->context, $this->victim;
			
			die "$this victim param is a must" unless $method;
			
			printf "%s postinit called for '%s'\n", ref $this, $method if $DEBUG;

			no strict 'refs';
			no warnings;
												
			my $orig = *{ $method }{CODE};
			
			*{ $method } = sub { 
			
				my $this = $this;
				
				__pre( $this, @_ ); 
				
					$this->pre->( $this, @_ ); 
					
						my @result = $orig->( @_ ); 
								
						$this->result( @result );
						
					$this->post->( $this, @_ ); 

				__post( $this, @_ ); 
				
				return @result; 
			};
	
	return $this;
	}

1;
__END__

=head1 NAME

Hook::Heckle - create pre and post hooks

=head1 SYNOPSIS

  use Hook::Heckle;

	my $notify = sub 
	{ 			
		my $this = shift;
		
		printf "Model is informing observers because '%s' change\n", $this->victim and $_[0]->notify_observers( 'update' ) if $_[1]; 
		
		@_;			
	};

	Hook::Heckle->new( context => 'InputField::String', victim => 'max', pre => sub { $_[0]->{aaa} = 1; }, post => $notify );
	
	Hook::Heckle->new( context => 'InputField::String', victim => 'text', post => $notify );

=head1 DESCRIPTION

Creating hooks to subroutines is issued by many other cpan modules. See

=over 4

=item *

L<Class::Hook>

=item * 

L<Hook::Scope> 

=item * 

L<Hook::WrapSub>

=item *

L<Hook::LexWrap>

=item * 

L<Hook::PrePostCall>

=back

But this didnt kept me from writing a new one. It is a base class and can be inherited.

=head2 CLASSES

=head3 Hook::Heckle

=over 4

=item PROPERTIES

Any property has a method and parameter to C<new> counterpart.

=over 4

=item victim 

The method or subroutine to hook at.

=item context (default: main)

Package name of the method or subroutine.

=item pre( $this, @_ )

Reference to sub which will be called B<before> execution of the C<victim>. First argument will be the
C<Hook::Heckel> object and second the original arguments of the victim.

=item post( $this, @_ )

Reference to sub which will be called B<after> execution of the C<victim>. First argument will be the
C<Hook::Heckel> object and second the original arguments of the victim.

=item result

Array of the result from the C<victim>.

=back

=item METHODS

None.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Hook>, L<Hook::Scope>, L<Hook::WrapSub>, L<Hook::LexWrap>, L<Hook::PrePostCall> and L<Class::Maker>.

=cut
