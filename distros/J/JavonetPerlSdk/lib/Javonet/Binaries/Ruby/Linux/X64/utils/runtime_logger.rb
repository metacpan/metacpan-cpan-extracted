class RuntimeLogger

  @not_logged_yet = true

  def self.get_runtime_info
    begin
      "Ruby Managed Runtime Info:\n" \
        "Ruby Version: #{RUBY_VERSION}\n" \
        "Ruby Implementation: #{RUBY_ENGINE}\n" \
        "Current Directory: #{Dir.pwd}\n"
    rescue => e
      "Ruby Managed Runtime Info: Error while fetching runtime info"
    end
  end

  def self.print_runtime_info
    if @not_logged_yet
      puts get_runtime_info
      @not_logged_yet = false
    end
  end
end