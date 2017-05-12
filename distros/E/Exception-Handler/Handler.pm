package Exception::Handler;
use strict;
use vars qw( $VERSION );
$VERSION = 1.00_4; # Thu Dec 21 18:04:23 CST 2006

# --------------------------------------------------------
# Constructor
# --------------------------------------------------------
sub new { 
	my($this) = bless({ }, shift(@_));
	$this->{'errors'} = [@_];
	return $this
}

# --------------------------------------------------------
# Exception::Handler::error()
# --------------------------------------------------------
sub error { @{ $_->{'errors'} } } # very bad; very easy


# --------------------------------------------------------
# Exception::Handler::fail()
# --------------------------------------------------------
sub fail  {

   my($this) = shift(@_);
   my($throw_count) = $this->{'tflag'} || 0;

   {
     # I refuse to manually initialize a standard environment
     # variable.  This is an example where the warnings pragma
     # is going too far.  It's something we live with.
     local($^W) = undef;

     # if we're running in a CGI gateway iface, we need
     # to output the necessary HTTP headers
     if ( $ENV{'REQUEST_METHOD'} ) {

       print(<<__crash__) and exit;
Content-Type: text/html; charset=ISO-8859-1

<pre>
PROCESS TERMINATED DUE TO ERRORS
@{[ $this->trace(@_) ]}
</pre>
__crash__
     }
     else {

       print(<<__crash__) and exit;
PROCESS TERMINATED DUE TO ERRORS
@{[ $this->trace(@_) ]}
__crash__
     }
   }

   exit
}


# --------------------------------------------------------
# Exception::Handler::trace()
# --------------------------------------------------------
sub trace {

   my($this)    = shift(@_);
   my(@errors)  = @_; $this->{'errors'} = [@errors];
   my($errfile) = '';
   my($caught)  = '';
   my(
      $pak,    $file,  $line,  $sub,
      $hasargs, $wantarray, $evaltext, $req_OR_use,
      @stack,   $i,    $ialias
   );

   $ialias = 0;

   while (
      (
         $pak,    $file,  $line,  $sub,
         $hasargs, $wantarray, $evaltext, $req_OR_use
      ) = caller( $i++ )
     )
   {
      $ialias = $i - 2; next unless ($ialias > 0);

      if ( (split(/\:\:/, $sub))[0] ne __PACKAGE__ ) {

         push @stack, <<__ERR__
$ialias. $sub
    -called at line ($line) of $file
       @{[ ($hasargs)
            ? '-was called with args'
            : '-was called without args' ]}
       @{[ ($evaltext)
            ? '-was called to evalate text'
            : '-was not called to evaluate anything' ]}
__ERR__
      }
      else {
         $caught = qq[\012] . uc(qq[exception was raised at])
           . qq[ line ($line) of $file];
     }
   }

   $i = 0;

   if ( scalar(@errors) == 0 ) {

     push ( @errors, qq[[Unspecified error.  Frame no. $ialias...]] );
   }

   foreach (@errors) {

      $_ = ( defined($_) ) ? $_ : '';

      if (!length($_)) { $_ = qq[Something is wrong.  Frame no. $ialias...]; }
      else {

         $_ =~ s/^(?:\r|\n)//o; $_ =~ s/(?:\r|\n)$//o;

         $_ = qq[\012$_\012];
      }

      ++$i;
   }

   join(qq[\012] x 2, @errors)
   . ($caught ? $caught . qq[\012] : '')
   . qq[\012] . join(qq[\012] x 2, @stack);
}


# --------------------------------------------------------
# Exception::Handler::DESTROY()
# --------------------------------------------------------
sub DESTROY { } sub AUTOLOAD { }
1;

=pod

=head1 NAME

Exception::Handler - Report exceptions with formatted text call-stack

=head1 VERSION

1.00_2

=head1 @EXPORT, @EXPORT_OK

None.

=head1 Methods

   new()
   fail()
   trace()
   error()

=head2 AUTOLOAD-ed methods

None.

=head1 PREREQUISITES

None.

=head1 AUTHOR

Tommy Butler <cpan@atrixnet.com>

=head1 COPYRIGHT

Copyright(c) 2001-2003, Tommy Butler.  All rights reserved.

=head1 LICENSE

This library is free software, you may redistribute
and/or modify it under the same terms as Perl itself.

=cut

