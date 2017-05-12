package Email::Archive::Storage;
use Moo::Role;

requires qw/store retrieve search storage_connect/;
1;
