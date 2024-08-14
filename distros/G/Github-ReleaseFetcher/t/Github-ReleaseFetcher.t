use strict;
use warnings;

use Test2::V0;
use Test::Mock::HTTP::Tiny;

use Github::ReleaseFetcher;

# I'll give you one guess why I wrote this module
my ( $user, $project ) = qw{SeleniumHQ selenium};

my $bad_version_request = {
    url      => "$Github::ReleaseFetcher::BASE_URI/$user/$project/releases/latest",
    method   => 'GET',
    args     => {},
    response => {
        success => 0,
        content => 'I already have a wristwatch',
        reason  => 'u dumb',
    }
};

my $good_version_request = {
    url      => "$Github::ReleaseFetcher::BASE_URI/$user/$project/releases/latest",
    method   => 'GET',
    args     => {},
    response => {
        success => 1,
        url     => "$Github::ReleaseFetcher::BASE_URI/$user/$project/releases/666",
    }
};

my $bad_listing_request = {
    url      => "$Github::ReleaseFetcher::BASE_URI/$user/$project/releases/expanded_assets/666",
    method   => 'GET',
    args     => {},
    response => {
        success => 0,
        content => 'I already have a wristwatch',
        reason  => 'u dumb',
    }
};

local $/ = "";
my $content = <DATA>;

my $good_listing_request = {
    url      => "$Github::ReleaseFetcher::BASE_URI/$user/$project/releases/expanded_assets/666",
    method   => 'GET',
    args     => {},
    response => {
        success => 1,
        content => $content,
    }
};

Test::Mock::HTTP::Tiny->set_mocked_data( [$bad_version_request] );
like( dies { Github::ReleaseFetcher::fetch( undef, $user, $project ) }, qr/u dumb/, "Failing to redirect to the release version explodes" );

Test::Mock::HTTP::Tiny->set_mocked_data( [ $good_version_request, $bad_listing_request ] );
like( dies { Github::ReleaseFetcher::fetch( undef, $user, $project ) }, qr/u dumb/, "expanded assets page failing explodes" );

my @gut = (
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-dotnet-strongnamed-4.23.0.zip',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-java-4.23.0.zip',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.1.jar',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.0.zip',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-dotnet-4.23.0.zip',
    'http://github.com//SeleniumHQ/selenium/archive/refs/tags/selenium-4.23.0.tar.gz',
    'http://github.com//SeleniumHQ/selenium/archive/refs/tags/selenium-4.23.0.zip',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-java-4.23.1.zip',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.0.jar',
    'http://github.com//SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.1.zip'
);

Test::Mock::HTTP::Tiny->set_mocked_data( [ $good_version_request, $good_listing_request ] );
my @out = Github::ReleaseFetcher::fetch( undef, $user, $project );

# Test2's bag builder is BAD DO NOT USE!!!!!!!!!!!!
@out = sort @out;
@gut = sort @gut;
is( \@out, \@gut, "Got expected output when process succeeds" );

done_testing();

__DATA__
<div data-view-component="true" class="Box Box--condensed mt-3">
    <ul data-view-component="true">
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-dotnet-4.23.0.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-dotnet-4.23.0.zip</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">10.4 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-19T10:27:29Z" class="no-wrap" prefix="">2024-07-19T10:27:29Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-dotnet-strongnamed-4.23.0.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-dotnet-strongnamed-4.23.0.zip</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">10.4 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-19T10:27:39Z" class="no-wrap" prefix="">2024-07-19T10:27:39Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-java-4.23.0.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-java-4.23.0.zip</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">30.6 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-19T10:27:47Z" class="no-wrap" prefix="">2024-07-19T10:27:47Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-java-4.23.1.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-java-4.23.1.zip</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">30.6 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-08-09T12:43:00Z" class="no-wrap" prefix="">2024-08-09T12:43:00Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.0.jar" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-server-4.23.0.jar</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">36.2 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-19T10:28:01Z" class="no-wrap" prefix="">2024-07-19T10:28:01Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.0.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-server-4.23.0.zip</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">87.6 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-19T10:28:20Z" class="no-wrap" prefix="">2024-07-19T10:28:20Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.1.jar" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-server-4.23.1.jar</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">36.2 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-08-09T12:42:56Z" class="no-wrap" prefix="">2024-08-09T12:42:56Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-package color-fg-muted">
    <path d="m8.878.392 5.25 3.045c.54.314.872.89.872 1.514v6.098a1.75 1.75 0 0 1-.872 1.514l-5.25 3.045a1.75 1.75 0 0 1-1.756 0l-5.25-3.045A1.75 1.75 0 0 1 1 11.049V4.951c0-.624.332-1.201.872-1.514L7.122.392a1.75 1.75 0 0 1 1.756 0ZM7.875 1.69l-4.63 2.685L8 7.133l4.755-2.758-4.63-2.685a.248.248 0 0 0-.25 0ZM2.5 5.677v5.372c0 .09.047.171.125.216l4.625 2.683V8.432Zm6.25 8.271 4.625-2.683a.25.25 0 0 0 .125-.216V5.677L8.75 8.432Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/releases/download/selenium-4.23.0/selenium-server-4.23.1.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">selenium-server-4.23.1.zip</span>
    <span data-view-component="true" class="Truncate-text"></span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-sm-left flex-auto ml-md-3">87.6 MB</span>
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-08-09T12:43:04Z" class="no-wrap" prefix="">2024-08-09T12:43:04Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-file-zip color-fg-muted">
    <path d="M3.5 1.75v11.5c0 .09.048.173.126.217a.75.75 0 0 1-.752 1.298A1.748 1.748 0 0 1 2 13.25V1.75C2 .784 2.784 0 3.75 0h5.586c.464 0 .909.185 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v8.586A1.75 1.75 0 0 1 12.25 15h-.5a.75.75 0 0 1 0-1.5h.5a.25.25 0 0 0 .25-.25V4.664a.25.25 0 0 0-.073-.177L9.513 1.573a.25.25 0 0 0-.177-.073H7.25a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1 0-1.5h-3a.25.25 0 0 0-.25.25Zm3.75 8.75h.5c.966 0 1.75.784 1.75 1.75v3a.75.75 0 0 1-.75.75h-2.5a.75.75 0 0 1-.75-.75v-3c0-.966.784-1.75 1.75-1.75ZM6 5.25a.75.75 0 0 1 .75-.75h.5a.75.75 0 0 1 0 1.5h-.5A.75.75 0 0 1 6 5.25Zm.75 2.25h.5a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1 0-1.5ZM8 6.75A.75.75 0 0 1 8.75 6h.5a.75.75 0 0 1 0 1.5h-.5A.75.75 0 0 1 8 6.75ZM8.75 3h.5a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1 0-1.5ZM8 9.75A.75.75 0 0 1 8.75 9h.5a.75.75 0 0 1 0 1.5h-.5A.75.75 0 0 1 8 9.75Zm-1 2.5v2.25h1v-2.25a.25.25 0 0 0-.25-.25h-.5a.25.25 0 0 0-.25.25Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/archive/refs/tags/selenium-4.23.0.zip" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">Source code</span>
    <span data-view-component="true" class="Truncate-text">(zip)</span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-18T12:11:25Z" class="no-wrap" prefix="">2024-07-18T12:11:25Z</relative-time></span>
</div></li>
        <li data-view-component="true" class="Box-row d-flex flex-column flex-md-row">      <div data-view-component="true" class="d-flex flex-justify-start col-12 col-lg-9">
        <svg aria-hidden="true" height="16" viewBox="0 0 16 16" version="1.1" width="16" data-view-component="true" class="octicon octicon-file-zip color-fg-muted">
    <path d="M3.5 1.75v11.5c0 .09.048.173.126.217a.75.75 0 0 1-.752 1.298A1.748 1.748 0 0 1 2 13.25V1.75C2 .784 2.784 0 3.75 0h5.586c.464 0 .909.185 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v8.586A1.75 1.75 0 0 1 12.25 15h-.5a.75.75 0 0 1 0-1.5h.5a.25.25 0 0 0 .25-.25V4.664a.25.25 0 0 0-.073-.177L9.513 1.573a.25.25 0 0 0-.177-.073H7.25a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1 0-1.5h-3a.25.25 0 0 0-.25.25Zm3.75 8.75h.5c.966 0 1.75.784 1.75 1.75v3a.75.75 0 0 1-.75.75h-2.5a.75.75 0 0 1-.75-.75v-3c0-.966.784-1.75 1.75-1.75ZM6 5.25a.75.75 0 0 1 .75-.75h.5a.75.75 0 0 1 0 1.5h-.5A.75.75 0 0 1 6 5.25Zm.75 2.25h.5a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1 0-1.5ZM8 6.75A.75.75 0 0 1 8.75 6h.5a.75.75 0 0 1 0 1.5h-.5A.75.75 0 0 1 8 6.75ZM8.75 3h.5a.75.75 0 0 1 0 1.5h-.5a.75.75 0 0 1 0-1.5ZM8 9.75A.75.75 0 0 1 8.75 9h.5a.75.75 0 0 1 0 1.5h-.5A.75.75 0 0 1 8 9.75Zm-1 2.5v2.25h1v-2.25a.25.25 0 0 0-.25-.25h-.5a.25.25 0 0 0-.25.25Z"></path>
</svg>
        <a href="/SeleniumHQ/selenium/archive/refs/tags/selenium-4.23.0.tar.gz" rel="nofollow" data-turbo="false" data-view-component="true" class="Truncate">
    <span data-view-component="true" class="Truncate-text text-bold">Source code</span>
    <span data-view-component="true" class="Truncate-text">(tar.gz)</span>
</a></div>      <div data-view-component="true" class="d-flex flex-auto flex-justify-end col-md-4 ml-3 ml-md-0 mt-1 mt-md-0 pl-1 pl-md-0">
          <span style="white-space: nowrap;" data-view-component="true" class="color-fg-muted text-right flex-shrink-0 flex-grow-0 ml-3"><relative-time datetime="2024-07-18T12:11:25Z" class="no-wrap" prefix="">2024-07-18T12:11:25Z</relative-time></span>
</div></li>
</ul>
</div>
