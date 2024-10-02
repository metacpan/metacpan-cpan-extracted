require_relative './../../external_lib/singleton'

class TypeCache
  include Singleton

  attr_accessor :type_cache

  def initialize
    @type_cache = []
  end

  def cache_type(type_regex)
    @type_cache << type_regex
  end

  def is_type_cache_empty?
    @type_cache.empty?
  end

  def is_type_allowed(type_to_check)
    if type_to_check.is_a?(Module)
      name_to_check = type_to_check.name
    else
      name_to_check = "#{type_to_check.class.name}::#{type_to_check.name}"
    end

    @type_cache.any? do
|pattern| /#{pattern}/.match?(name_to_check)
    end
  end

  def get_cached_types
    @type_cache
  end

  def clear_cache
    @type_cache.clear
    0
  end
end