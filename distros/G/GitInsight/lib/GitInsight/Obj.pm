package GitInsight::Obj;

 use strict;
 use warnings;
 use utf8;

 #a fork of Mojo::Base

  our $feature = eval {
     require feature;
     feature->import();
     1;
 };


 # Only Perl 5.14+ requires it on demand
 use IO::Handle ();

 # Protect subclasses using AUTOLOAD
 sub DESTROY { }

 sub import {
     my $class = shift;
     return unless my $flag = shift;

     # Base
     if ( $flag eq '-base' ) { $flag = $class }

     # Strict
     elsif ( $flag eq '-strict' ) { $flag = undef }

     # Module
     elsif ( ( my $file = $flag ) && !$flag->can('new') ) {
         $file =~ s!::|'!/!g;
         require "$file.pm";
     }

     # ISA
     if ($flag) {
         my $caller = caller;
         no strict 'refs';
         push @{"${caller}::ISA"}, $flag;
         *{"${caller}::has"} = sub { attr( $caller, @_ ) };
     }

     # Mojo modules are strict!
     $_->import for qw(strict warnings utf8);
     if ($feature) {
         feature->import(':5.10');
     }
 }

 sub attr {
     my ( $self, $attrs, $default ) = @_;
     return unless ( my $class = ref $self || $self ) && $attrs;

     die 'Default has to be a code reference or constant value'
         if ref $default && ref $default ne 'CODE';

     for my $attr ( @{ ref $attrs eq 'ARRAY' ? $attrs : [$attrs] } ) {
         die qq{Attribute "$attr" invalid}
             unless $attr =~ /^[a-zA-Z_]\w*$/;

         # Header (check arguments)
         my $code = "package $class;\nsub $attr {\n  if (\@_ == 1) {\n";

         # No default value (return value)
         unless ( defined $default ) { $code .= "    return \$_[0]{'$attr'};" }

         # Default value
         else {

             # Return value
             $code
                 .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

             # Return default value
             $code .= "    return \$_[0]{'$attr'} = ";
             $code .=
                 ref $default eq 'CODE'
                 ? '$default->($_[0]);'
                 : '$default;';
         }

         # Store value
         $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

         # Footer (return invocant)
         $code .= "  \$_[0];\n}";

         warn "-- Attribute $attr in $class\n$code\n\n"
             if $ENV{GitInsight_OBJ_DEBUG};
         die "GitInsight::Obj error: $@" unless eval "$code;1";
     }
 }

 sub new {
     my $class = shift;
     bless @_ ? @_ > 1 ? {@_} : { %{ $_[0] } } : {}, ref $class || $class;
 }

 sub tap {
     my ( $self, $cb ) = @_;
     $_->$cb for $self;
     return $self;
 }

 1;
