# ABSTRACT: Syntactic sugar for a script's main routine
use strict;
use warnings;

package Devel::Main;

our $VERSION = 0.005;

sub import {
    my $class  = shift;
    @_ = 'main' unless @_;
    
    my $opts   = ref($_[0]) ? shift : {};
    my $caller = $opts->{into} // scalar(caller($opts->{into_level} // 0));
    
    while (@_) {
        my $name = shift;
        my $args = ref($_[0]) ? shift : {};
        my $gen  = $class->can("$name\_generator")
            or do { require Carp; Carp::croak("$class does not export sub '$name'") };
        my $code = $gen->( $class, $name, $args );
        
        my $as = join '', grep defined, (
            $args->{ -prefix },
            ($args->{ -as } // $name),
            $args->{ -suffix },
        );
        
        no strict 'refs';
        *{"$caller\::$as"} = $code;
    }
}

sub main_generator {
    my ( $class, $name, $args ) = @_;

    my $run_sub_name = $args->{'run_sub_name'} // "run_$name";
    my $exit         = $args->{'exit'}         // 1;

    return sub (&) {
        my ($main_sub) = @_;

        # If we're called from a script, run main and exit
        if ( !defined caller(1) ) {
            $main_sub->();
            exit(0) if $exit;
        }

        # Otherwise, create a sub that turns its arguments into @ARGV
        else {
            no strict 'refs';
            my $package = caller;
            *{"${package}::$run_sub_name"} = sub {
                local @ARGV = @_;
                return $main_sub->();
            };

            # Return 1 to make the script pass 'require'
            return 1;
        }
    };
}

1;

__END__

=pod

=head1 NAME

Devel::Main - Syntactic sugar for a script's main routine

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Devel::Main 'main';
  
  main {
    # Your main routine goes here
  };

=head1 DESCRIPTION

This module provides a clean way of specifying your script's main routine.

=head1 METHODS

=head2 main()

Declares your script's main routine. Exits when done.

If, instead of executing your script, you load it with C<use> or C<require>, C<main> creates a subroutine named C<run_main> in the current package. You can then call this subroutine to run your main routine. Arguments passed to this subroutine will override C<@ARGV>.

Example:

  require './my_script.pl';
  
  run_main( 'foo' );  # Calls the main routine with @ARGV = ('foo')

If you alias the 'main' routine to another name, the "run" method will also be aliased. For example, if 'my_script.pl' had said:

  use Devel::Main main => { -as => 'primary' };
  
  primary {
    # Main code here
  };

then the installed subroutine would be called 'run_primary'.

You can also control whether or not the script exits after the main routine via the import parameter 'exit'.

   use Devel::Main 'main' => { 'exit' => 0 };
   
   main {
     # Main routine
   };
   print "Still running\n";

Finally, you can change the name of the subroutine to call the main routine via the import parameter 'run_sub_name'.

   # In 'my_script.pl'
   use Devel::Main 'main' => { 'run_sub_name' => 'run_the_main_routine' };
   
   # In other (test?) script
   require './my_script.pl';
   
   run_the_main_routine('bar'); # Calls the main routine with @ARGV = ('bar');

=head1 METHODS

=head1 CREDITS

This module was inspired by brian d foy's article
L<Five Ways to Improve Your Perl Programming|http://www.onlamp.com/2007/04/12/five-ways-to-improve-your-perl-programming.html>.

=head1 AUTHOR

Stephen Nelson <stephenenelson@mac.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Stephen Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
