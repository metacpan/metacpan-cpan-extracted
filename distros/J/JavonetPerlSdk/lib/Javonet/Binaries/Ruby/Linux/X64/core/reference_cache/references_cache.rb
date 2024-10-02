require_relative './../../external_lib/singleton'
require_relative './../../external_lib/securerandom'

class ReferencesCache
  include Singleton

  def initialize
    @references_cache = Hash.new
  end

  def cache_reference(object_reference)
    uuid_ = SecureRandom.uuid
    @references_cache[uuid_] = object_reference
    uuid_
  end

  def resolve_reference(guid)
    if @references_cache[guid].nil?
      raise 'Unable to resolve reference with id: ' + guid.to_s
    else
      @references_cache[guid]
    end
  end

  def delete_reference(guid)
    if @references_cache[guid].nil?
      raise 'Object not found in reference cache'
    else
      @references_cache.delete(guid)
      0
    end
  end
end