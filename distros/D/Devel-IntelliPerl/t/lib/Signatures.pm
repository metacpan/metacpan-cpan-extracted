package 
  Signatures;
our $VERSION = '0.04';

use Moose;
use Path::Class::File;
use MooseX::Method::Signatures;

use Moose::Util::TypeConstraints;

BEGIN { class_type 'PathClassFile', { class => 'Path::Class::File' }; }

method file returns (PathClassFile) {
    return new Path::Class::File;
}

1;