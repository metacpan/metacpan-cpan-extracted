use Test2::V0 -no_srand => 1;
use Alien::Build::Wizard::Questions qw( QUESTION_URL );

imported_ok 'QUESTION_URL';

foreach my $key (sort @Alien::Build::Wizard::Questions::EXPORT_OK)
{
  my $value = Alien::Build::Wizard::Questions->$key;
  note "$key=$value";
}

done_testing;
