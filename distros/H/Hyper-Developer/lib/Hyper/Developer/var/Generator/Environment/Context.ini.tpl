[Global]
base_path=[% this.get_base_path %]
namespace=[% this.get_namespace %]

[Class]
translator=Hyper.Translator.Noop
template=Hyper.Template.HTC
application=Hyper.Application.Default

[Hyper::Application::Default]
;template=

[Hyper::Persistence]
cache_path=/tmp

[Hyper::Error]
;plain_template=Hyper/Error/plain_error.htc
;html_template=Hyper/Error/html_error.htc
