package Git::Gitalist::Serializable;

use Moose::Role;
use MooseX::Storage;

with Storage( traits => ['OnlyWhenBuilt'] );

1;
