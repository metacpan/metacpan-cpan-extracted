# HTML-SocialMedia-Hashtag

## DESCRIPTION
Get #hashtags and @usernames from html

## SYNOPSIS

    use HTML::SocialMedia::Hashtag;
    my $scanner = HTML::SocialMedia::Hashtag -> new( text => 'text with #hashtag and @username' );
    my @hashtags  = $object -> hashtags();
    my @usernames = $object -> usernames();

##METHODS

### hashtags()
Get lowercased and unique hashtags from html

### all_hashtags()
Get all hashtags

### nicknames()
Get unique nicknames from html

### all_nicknames()
Get all nicknames
