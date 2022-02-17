# -*- ruby -*-

/^our \$VERSION = "(.+?)"/ =~ File.read("lib/Groonga/HTTP.pm")
version = $1

desc "Tag for #{version}"
task :tag do
  sh("git", "tag", "-a", version, "-m", "#{version} has been released!!!")
  sh("git", "push", "--tags")
end

namespace :version do
  desc "Update version"
  task :update do
    new_version = ENV["NEW_VERSION"]
    if new_version.nil?
      raise "Specify new version as VERSION environment variable value"
    end

    http_pm_content = File.read("lib/Groonga/HTTP.pm").gsub(/^our \$VERSION = ".+?"/) do
      "our $VERSION = \"#{new_version}\""
    end
    File.open("lib/Groonga/HTTP.pm", "w") do |http_pm|
      http_pm.print(http_pm_content)
    end
  end
end
