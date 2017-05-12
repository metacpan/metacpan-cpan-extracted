use Test::More tests => 2;
use Test::NoWarnings;
use English qw( -no_match_vars ) ;

my $SYNOPSIS = <<'EOT'

  use LaTeX::Table;
  #use Number::Format qw(:subs);  # use mighty CPAN to format values

  my $header = [
      [ 'Item:2c', '' ],
      ['\cmidrule(r){1-2}'],
      [ 'Animal', 'Description', 'Price' ]
  ];
  
  my $data = [
      [ 'Gnat',      'per gram', '13.65'   ],
      [ '',          'each',      '0.0173' ],
      [ 'Gnu',       'stuffed',  '92.59'   ],
      [ 'Emu',       'stuffed',  '33.33'   ],
      [ 'Armadillo', 'frozen',    '8.99'   ],
  ];

  
  my $table = LaTeX::Table->new(
  	{   
        filename    => 'prices.tex',
        maincaption => 'Price List',
        caption     => 'Try our special offer today!',
        label       => 'table:prices',
        position    => 'htb',
        header      => $header,
        data        => $data,
  	}
  );
  
  # write LaTeX code in prices.tex
  $table->generate_string();

  # callback functions help you to format values easily (as
  # a great alternative to LaTeX packages like rccol)
  #
  # Here, the first colum and the header is printed in upper
  # case and the third colum is formatted with format_price()
  $table->set_callback(sub { 
       my ($row, $col, $value, $is_header ) = @_;
       if ($col == 0 || $is_header) {
           $value = uc $value;
       }
       elsif ($col == 2 && !$is_header) {
         #  $value = format_price($value, 2, '');
       }
       return $value;
  });     
  
  print $table->generate_string();

EOT
;

eval $SYNOPSIS;
ok(!$EVAL_ERROR,"Test Synopsis") || diag $EVAL_ERROR;

