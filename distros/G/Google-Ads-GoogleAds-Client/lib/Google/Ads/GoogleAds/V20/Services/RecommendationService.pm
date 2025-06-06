# Copyright 2020, Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Ads::GoogleAds::V20::Services::RecommendationService;

use strict;
use warnings;
use base qw(Google::Ads::GoogleAds::BaseService);

sub apply {
  my $self         = shift;
  my $request_body = shift;
  my $http_method  = 'POST';
  my $request_path = 'v20/customers/{+customerId}/recommendations:apply';
  my $response_type =
'Google::Ads::GoogleAds::V20::Services::RecommendationService::ApplyRecommendationResponse';

  return $self->SUPER::call($http_method, $request_path, $request_body,
    $response_type);
}

sub dismiss {
  my $self         = shift;
  my $request_body = shift;
  my $http_method  = 'POST';
  my $request_path = 'v20/customers/{+customerId}/recommendations:dismiss';
  my $response_type =
'Google::Ads::GoogleAds::V20::Services::RecommendationService::DismissRecommendationResponse';

  return $self->SUPER::call($http_method, $request_path, $request_body,
    $response_type);
}

sub generate {
  my $self         = shift;
  my $request_body = shift;
  my $http_method  = 'POST';
  my $request_path = 'v20/customers/{+customerId}/recommendations:generate';
  my $response_type =
'Google::Ads::GoogleAds::V20::Services::RecommendationService::GenerateRecommendationsResponse';

  return $self->SUPER::call($http_method, $request_path, $request_body,
    $response_type);
}

1;
