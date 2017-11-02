use strict;
use Test::More 0.98;
use File::Spec;
use lib 't/lib-dbicschema';
use Schema;

use_ok 'GraphQL::Plugin::Convert::DBIC';

my $expected = join '', <DATA>;
my $dbic_class = 'Schema';
my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
  sub { $dbic_class->connect }
);
my $got = $converted->{schema}->to_doc;
#open my $fh, '>', 'tf'; print $fh $got; # uncomment to regenerate
is $got, $expected;

done_testing;

__DATA__
type Blog {
  blog_tags: [BlogTag]
  content: String!
  created_time: String!
  id: Int!
  location: String
  subtitle: String
  tags: [BlogTag]
  timestamp: DateTime!
  title: String!
}

input BlogInput {
  content: String!
  created_time: String!
  location: String
  subtitle: String
  timestamp: DateTime!
  title: String!
}

type BlogTag {
  blog: Blog
  id: Int!
  name: String!
}

input BlogTagInput {
  blog_id: Int!
  name: String!
}

scalar DateTime

type Mutation {
  createBlog(input: BlogInput!): Blog
  createBlogTag(input: BlogTagInput!): BlogTag
  createPhoto(input: PhotoInput!): Photo
  createPhotoset(input: PhotosetInput!): Photoset
  deleteBlog(id: Int!): Boolean
  deleteBlogTag(id: Int!): Boolean
  deletePhoto(id: String!): Boolean
  deletePhotoset(id: String!): Boolean
  updateBlog(id: Int!, input: BlogInput!): Blog
  updateBlogTag(id: Int!, input: BlogTagInput!): BlogTag
  updatePhoto(id: String!, input: PhotoInput!): Photo
  updatePhotoset(id: String!, input: PhotosetInput!): Photoset
}

type Photo {
  country: String
  description: String
  id: String!
  idx: Int
  is_glen: String
  isprimary: String
  large: String
  lat: String
  locality: String
  lon: String
  medium: String
  original: String
  original_url: String
  photoset: Photoset
  photosets: [Photoset]
  region: String
  set: Photoset
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

input PhotoInput {
  country: String
  description: String
  idx: Int
  is_glen: String
  isprimary: String
  large: String
  lat: String
  locality: String
  lon: String
  medium: String
  original: String
  original_url: String
  photoset_id: String!
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

type Photoset {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String!
  farm: Int!
  id: String!
  idx: Int!
  needs_interstitial: Int
  photos: [Photo]
  primary: Photo
  primary_photo: Photo
  secret: String!
  server: String!
  timestamp: DateTime!
  title: String!
  videos: Int
  visibility_can_see_set: Int
}

input PhotosetInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String!
  farm: Int!
  idx: Int!
  needs_interstitial: Int
  photo_id: String!
  secret: String!
  server: String!
  timestamp: DateTime!
  title: String!
  videos: Int
  visibility_can_see_set: Int
}

type Query {
  blog(id: [Int!]!): [Blog]
  blogTag(id: [Int!]!): [BlogTag]
  photo(id: [String!]!): [Photo]
  photoset(id: [String!]!): [Photoset]
  # list of ORs each of which is list of ANDs
  searchBlog(input: [[BlogInput!]!]!): [Blog]
  # list of ORs each of which is list of ANDs
  searchBlogTag(input: [[BlogTagInput!]!]!): [BlogTag]
  # list of ORs each of which is list of ANDs
  searchPhoto(input: [[PhotoInput!]!]!): [Photo]
  # list of ORs each of which is list of ANDs
  searchPhotoset(input: [[PhotosetInput!]!]!): [Photoset]
}
