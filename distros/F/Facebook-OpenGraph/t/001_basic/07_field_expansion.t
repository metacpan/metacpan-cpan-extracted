use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
eval "use YAML qw(LoadFile)";
plan skip_all => "YAML is not installed." if $@;

subtest 'parse fields param' => sub {
    my $fb = Facebook::OpenGraph->new;
    
    subtest 'string' => sub {
        is(
            $fb->prep_fields_recursive('fbmenlopark'),
            'fbmenlopark',
            'stringified field',
        );
    };

    subtest 'simple array ref' => sub {
        is(
            $fb->prep_fields_recursive([qw/4 go.hagiwara oklahomer.docs/]),
            '4,go.hagiwara,oklahomer.docs',
            'parse from array ref',
        );
    };

    subtest 'complex fields param' => sub {
        my $fields = LoadFile('t/resource/fields.yaml');
        my $fields_str = $fb->prep_fields_recursive($fields);
            
        my $user_field_match = $fields_str =~ s/\A (name,email,albums) //x;
        is $user_field_match, 1, 'user fields';
    
        my $albums_limit_match = $fields_str =~ s/(\A \.limit\(5\) | \.limit\(5\) \z)//x;
        is $albums_limit_match, 1, 'albums limit';
        my $albums_fields_match = $fields_str =~ s/\A \.fields\(name,photos(.*)\) \z/$1/x;
        is $albums_fields_match, 1, 'albums fields';
    
        my $photos_limit_match = $fields_str =~ s/(\A \.limit\(3\) | \.limit\(3\) \z)//x;
        is $photos_limit_match, 1, 'photos limit';
        my $photos_fields_match = $fields_str =~ s/\A \.fields\(name,picture,tags(.*)\) /$1/x;
        is $photos_fields_match, 1, 'photos fields';
    
        my $tags_limit_match = $fields_str =~ s/\A \.limit\(2\) \z//x;
        is $tags_limit_match, 1, 'tags limit';
    
        is $fields_str, '', 'all fields are done';
    };
};

done_testing;
