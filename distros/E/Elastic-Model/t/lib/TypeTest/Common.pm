package TypeTest::Common;

use Elastic::Doc;
use DateTime();

#===================================
has 'datetime_attr' => (
#===================================
    is  => 'ro',
    isa => 'DateTime'
);

no Elastic::Doc;

1;
