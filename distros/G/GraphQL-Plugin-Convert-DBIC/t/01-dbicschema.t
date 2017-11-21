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

input BlogCreateInput {
  content: String!
  created_time: String!
  location: String
  subtitle: String
  timestamp: DateTime!
  title: String!
}

input BlogMutateInput {
  content: String
  created_time: String
  id: Int!
  location: String
  subtitle: String
  timestamp: DateTime
  title: String
}

input BlogSearchInput {
  content: String
  created_time: String
  location: String
  subtitle: String
  timestamp: DateTime
  title: String
}

type BlogTag {
  blog: Blog!
  id: Int!
  name: String!
}

input BlogTagCreateInput {
  blog: BlogMutateInput!
  name: String!
}

input BlogTagMutateInput {
  id: Int!
  name: String
}

input BlogTagSearchInput {
  name: String
}

type Mutation {
  createBlog(input: [BlogCreateInput!]!): [Blog]
  createBlogTag(input: [BlogTagCreateInput!]!): [BlogTag]
  createPhoto(input: [PhotoCreateInput!]!): [Photo]
  createPhotoset(input: [PhotosetCreateInput!]!): [Photoset]
  deleteBlog(input: [BlogMutateInput!]!): [Boolean]
  deleteBlogTag(input: [BlogTagMutateInput!]!): [Boolean]
  deletePhoto(input: [PhotoMutateInput!]!): [Boolean]
  deletePhotoset(input: [PhotosetMutateInput!]!): [Boolean]
  updateBlog(input: [BlogMutateInput!]!): [Blog]
  updateBlogTag(input: [BlogTagMutateInput!]!): [BlogTag]
  updatePhoto(input: [PhotoMutateInput!]!): [Photo]
  updatePhotoset(input: [PhotosetMutateInput!]!): [Photoset]
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

input PhotoCreateInput {
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
  photoset: PhotosetMutateInput
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

input PhotoMutateInput {
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
  region: String
  small: String
  square: String
  taken: DateTime
  thumbnail: String
}

input PhotoSearchInput {
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

input PhotosetCreateInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String!
  farm: Int!
  idx: Int!
  needs_interstitial: Int
  primary_photo: PhotoMutateInput
  secret: String!
  server: String!
  timestamp: DateTime!
  title: String!
  videos: Int
  visibility_can_see_set: Int
}

input PhotosetMutateInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String
  farm: Int
  id: String!
  idx: Int
  needs_interstitial: Int
  secret: String
  server: String
  timestamp: DateTime
  title: String
  videos: Int
  visibility_can_see_set: Int
}

input PhotosetSearchInput {
  can_comment: Int
  count_comments: Int
  count_views: Int
  date_create: Int
  date_update: Int
  description: String
  farm: Int
  idx: Int
  needs_interstitial: Int
  secret: String
  server: String
  timestamp: DateTime
  title: String
  videos: Int
  visibility_can_see_set: Int
}

type Query {
  blog(id: [Int!]!): [Blog]
  blogTag(id: [Int!]!): [BlogTag]
  photo(id: [String!]!): [Photo]
  photoset(id: [String!]!): [Photoset]
  # input to search
  searchBlog(input: BlogSearchInput!): [Blog]
  # input to search
  searchBlogTag(input: BlogTagSearchInput!): [BlogTag]
  # input to search
  searchPhoto(input: PhotoSearchInput!): [Photo]
  # input to search
  searchPhotoset(input: PhotosetSearchInput!): [Photoset]
}
