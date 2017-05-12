use Test::More;
use warnings;
use strict;

BEGIN
{
    use_ok('Document::Transform');
    use_ok('Document::Transform::Role::Backend');
    use_ok('Document::Transform::Role::Transformer');
    use_ok('Document::Transform::Transformer');
    use_ok('Document::Transform::Backend::MongoDB');
}

done_testing();
