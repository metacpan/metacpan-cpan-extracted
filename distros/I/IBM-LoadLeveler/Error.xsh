# -*- Perl -*-
=pod

=head1 Error API

IBM::Loadleveler - Error API

=head1 SYNOPSIS

  use IBM::Loadleveler

  # Error API function

  ll_error($errObj,1 | 2 );

or

  ll_error(1 | 2);

=head1 DESCRIPTION

The error handling API takes an error object and prints an error messages, the location depends on the parameter

=over 4

=item 1 print error messages to stdout

=item 2 print error message to stderr

=back

Any other value no error message printed

Starting with version 1.0.6 the errObj is now being returned in the package global B<$IBM::LoadLeveler::errObj> and not via the return.  The reasons for doing this are:

=over 4

=item * It's an error, why would you want more than one ?

=item * All you can do with it is pass it to ll_error

=item * If you pass an errObj to the ll_error function it is destroyed

=item * It makes the code much neater

=back

=head1 SEE ALSO

L<LoadLeveler>

L<DataAccess>

L<perl>

IBM LoadLeveler for AIX 5L: Using and Administering

=cut


char *
ll_error(a,...)
	CASE: items == 1

          int  a
	  CODE:
          {
	    LL_element *errObj=(LL_element *)SvIV(get_sv("IBM::LoadLeveler::errObj",FALSE));
	    RETVAL=ll_error(&errObj,a);
	  }
	  OUTPUT:
		RETVAL
        CASE:
           LL_element *a

	  CODE:
          {
	    int b;

	    b=SvIV(ST(1));
	    RETVAL=ll_error(&a,b);
	  }
	  OUTPUT:
		RETVAL
 
