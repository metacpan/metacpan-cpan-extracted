use strict;
use warnings;

package JiftyTest::Model::Post;
our $VERSION = '0.07';

use Jifty::DBI::Schema;

use JiftyTest::Record schema {

  column title => 
    type        is 'text',
    label       is 'Title',
    default     is 'Untitled post';

  column content => 
    type        is 'text',
    label       is 'Content',
    render      as 'Textarea';

  column declarer => 
    type        is 'text',
    label       is 'Declarer';

};

# Your model-specific methods go here.

sub current_user_can { 
  return 1;
}

1;

