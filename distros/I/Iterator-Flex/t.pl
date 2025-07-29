use v5.10;

package Bar {

    use Scalar::Util 'blessed';
 
    use overload
      fallback => 0,
      bool     => sub { 1 },
      eq => sub {
          say 'Class: ', blessed( $_[0] ) // '<no class>';
          say 'Ref: ', ref $_[0];
          !!0;
      },
      q{""} => sub {
          say 'Class: ', blessed( $_[0] ) // '<no class>';
          say 'Ref: ', ref $_[0];
          'Bar';
      },
      ;

    sub new {
        my $class = shift;
        return bless sub { 'foo' }, $class;
    }

}


say Bar->new->();
