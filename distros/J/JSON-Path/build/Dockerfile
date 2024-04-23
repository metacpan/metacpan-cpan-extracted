FROM perl:stable
ENV TZ="America/Chicago"
RUN cpanm LWP::Protocol::https
RUN cpanm Dist::Zilla Pod::Elemental::Transformer::List \
    Dist::Zilla::Plugin::CheckChangeLog Dist::Zilla::Plugin::GithubMeta \
    Dist::Zilla::Plugin::MetaProvides::Package Dist::Zilla::Plugin::PodWeaver \
    Dist::Zilla::Plugin::Prereqs::FromCPANfile Dist::Zilla::Plugin::ReadmeAnyFromPod \
    Carp::Assert LV Readonly
