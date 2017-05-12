package inc::ProvidesData;
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

sub metadata
{
    {
        provides => {
            'Moose::Cookbook' => {
                file => 'lib/Moose/Cookbook.pod',
                version => '20.0',
            },
        },
    }
}
1;
