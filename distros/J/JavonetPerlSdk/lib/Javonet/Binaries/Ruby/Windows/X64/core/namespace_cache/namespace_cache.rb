require_relative './../../external_lib/singleton'

class NamespaceCache
  include Singleton

  attr_accessor :namespace_cache

  def initialize
    @namespace_cache = []
  end

  def cache_namespace(namespace_regex)
    @namespace_cache << namespace_regex
  end

  def is_namespace_cache_empty?
    @namespace_cache.empty?
  end

  def is_type_allowed(type_to_check)
    if type_to_check.is_a?(Module)
      name_to_check = type_to_check.name
    else
      name_to_check = "#{type_to_check.class.name}"
    end

    @namespace_cache.any? do |pattern|
      /#{pattern}/.match?(name_to_check)
    end
  end

def get_cached_namespaces
  @namespace_cache
end

def clear_cache
  @namespace_cache.clear
  0
end
end